import torch
import torch.functional as F
import torch.nn as nn
import torch.optim as optim
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Ellipse
from matplotlib.lines import Line2D

import logging
import time

class ClusterPlacer(object):
    def __init__(self, layout_info, **kwargs):
        self.xl, self.xh, self.yl, self.yh = \
            layout_info["xl"], layout_info["xh"], \
            layout_info["yl"], layout_info["yh"]
        self.width, self.height = \
            self.xh - self.xl, self.yh - self.yl
        self.half_width, self.half_height = \
            self.width / 2, self.height / 2
            
        self.device = kwargs.get("device", "cuda:0")
    
    def _plot_layout(self, x, y, rt_wh=None, print_lnk=False, figname="layout"):
        if rt_wh is None:
            rt_wh = np.ones_like(x)
        else:
            rt_wh = rt_wh.detach().cpu().numpy()
        rect = Rectangle((self.xl, self.yl), self.width, self.height, color='b', fill=False)

        fig, ax = plt.subplots(figsize=(6, 6))
        ax.add_artist(rect)

        if isinstance(x, torch.Tensor):
            x = x.detach().cpu().numpy()
        if isinstance(y, torch.Tensor):
            y = y.detach().cpu().numpy()

        # ax.scatter(self.ports_x, self.ports_y, color='blue', label='Points', alpha=1)
        areas = self.areas.detach().cpu().numpy()
        radius = np.sqrt(areas / np.pi) * 2
        x_axis = radius * np.sqrt(rt_wh)
        y_axis = radius / np.sqrt(rt_wh)
        # ax.scatter(x, y, radius, color='red', label='Points', alpha=0.5)
        for idx, (_x, _y, _xa, _ya) in enumerate(zip(x, y, x_axis, y_axis)):
            if idx < self.num_macros:
                color = 'red'
            else:
                color = 'blue'
            ax.add_artist(
                Ellipse((_x, _y), _xa, _ya, color=color, alpha=0.5))
            # ax.annotate(str(idx + 1), xy=(_x, _y), xytext=(_x, _y))
            
        if print_lnk:
            lnk_s = self.lnk_s.detach().cpu().numpy()
            max_lnk_s = torch.max(self.lnk_s)
            for rx, ry, lnkarr in zip(x, y, self.lnk_s):
                for _rx, _ry, lnk in zip(x, y, lnkarr):
                    ax.add_line(Line2D([rx, _rx], [ry, _ry], linewidth=lnk / max_lnk_s, color='black'))

        ax.set_xlim(self.xl - self.width * 0.01, self.xh + self.width * 0.01)
        ax.set_ylim(self.yl - self.height * 0.01, self.yh + self.height * 0.01)
        ax.set_aspect('equal', 'box')

        fig.savefig(f"{figname}.png")
        plt.close(fig)
    
class CoordinateClusterPlacer(ClusterPlacer):
    EPSILON = 1e-5
    def __init__(self, link_strength, cluster_areas, ratio_wh, num_macros, layout_info, **kwargs):
        super(CoordinateClusterPlacer, self).__init__(layout_info, **kwargs)
        
        self.num_clusters = cluster_areas.shape[0]
        self.lnk_s = torch.from_numpy(link_strength).float().to(self.device)
        self.areas = torch.from_numpy(cluster_areas).float().to(self.device)
        self.rt_wh = torch.from_numpy(ratio_wh).float().to(self.device)
        self.num_macros = num_macros
        
    def __call__(
        self,
        xy=None,
        num_iterations=1000,
        learning_rate=1, lr_decay=0.9,
        l_overlap_penalty=1, l_centripetal_penalty=1, tolerance=1,
        return_type="coordinate",
        **kwargs
    ):
        if xy is None:
            noise = lambda shape, amplitude: \
                (np.random.uniform(size=shape) - 0.5) \
                    * amplitude
            x = torch.from_numpy(
                self.width * \
                    (0.5 + noise((self.num_clusters,), 0.01))
                ).float().to(self.device)
            y = torch.from_numpy(
                self.height * \
                    (0.5 + noise((self.num_clusters,), 0.01))
                ).float().to(self.device)
        else:
            x, y = xy
            
        x.requires_grad_(True)
        y.requires_grad_(True)
        
        self.optimizer = optim.SGD(
            [x, y], lr=learning_rate)
        
        self.scheduler = optim.lr_scheduler.StepLR(
            self.optimizer, step_size=20, gamma=lr_decay
        )
        
        for it in range(num_iterations):
            l_overlap_penalty = it * 1e-4
            self.step(x, y, it, l_overlap_penalty, l_centripetal_penalty, tolerance)
            
        if hasattr(self, f"return_{return_type}"):
            return getattr(self, f"return_{return_type}")(
                           x, y, **kwargs)
        else:
            raise NotImplementedError
        
    def return_coordinate(self, x, y, **kwargs):
        return x, y
    
    def step(self, x, y, it, l_overlap_penalty=1, l_centripetal_penalty=1, tolerance=1):
        self.optimizer.zero_grad()
        obj, entries = \
            self.obj_fn(x, y, l_overlap_penalty, l_centripetal_penalty, tolerance)
        obj.backward()
        nn.utils.clip_grad_value_([x], self.width / 10)
        nn.utils.clip_grad_value_([y], self.height / 10)
        self.optimizer.step()
        self.scheduler.step()
        if it % 100 == 0:
            print(obj, entries)
            print("x     : ", x[-5:])
            print("x.grad: ", x.grad[-5:])
            print("y     : ", y[-5:])
            print("y.grad: ", y.grad[-5:])
        if it % 100 == 0:
            self.plot_layout(x, y)
    
    def obj_fn(self, x, y, l_overlap_penalty=1, l_centripetal_penalty=1, tolerance=1):
        EPSILON = CoordinateClusterPlacer.EPSILON
        
        # calculate distance
        diag_mask = ~torch.eye(self.num_clusters, dtype=bool)
        delta = lambda t: t.unsqueeze(1) - t.unsqueeze(0)
        delta_x = delta(x)#[diag_mask].view(self.num_clusters, -1)
        delta_y = delta(y)#[diag_mask].view(self.num_clusters, -1)
        distance = \
            torch.sqrt(delta_x ** 2 + delta_y ** 2 + EPSILON ** 2) - EPSILON
        masked_d = distance[diag_mask].view(self.num_clusters, -1)
        lnk_s = self.lnk_s#[diag_mask].view(self.num_clusters, -1)
        weighted_distance = \
            torch.sum(torch.multiply(
                masked_d,
                lnk_s[diag_mask].view(self.num_clusters, -1)
            )) / 2
        
        tan_theta = (delta_y + EPSILON) / (delta_x + EPSILON)
        squared_k = tan_theta ** 2
        radius = torch.sqrt(self.areas / np.pi) * 2
        x_axis = radius * torch.sqrt(self.rt_wh)
        squared_xa = x_axis ** 2
        y_axis = radius / torch.sqrt(self.rt_wh)
        squared_ya = y_axis ** 2
        distance_from_center = torch.sqrt(
            (torch.diag(squared_xa * squared_ya) @ (squared_k + 1) / 
            (torch.diag(squared_xa) @ squared_k 
           + torch.diag(squared_ya) @ torch.ones_like(squared_k)))
        )
        pair_sum_distance_from_center = (
            distance_from_center +
            distance_from_center.T
        )[diag_mask].view(self.num_clusters, -1)
        overlap = torch.clamp_min(
            pair_sum_distance_from_center - masked_d * tolerance,
            min=0)
        masked_dx = \
            (torch.sqrt(delta_x ** 2 + EPSILON ** 2) - EPSILON)\
                [diag_mask].view(self.num_clusters, -1)
        masked_dy = \
            (torch.sqrt(delta_y ** 2 + EPSILON ** 2) - EPSILON)\
                [diag_mask].view(self.num_clusters, -1)
        
        pair_x_axis = x_axis.unsqueeze(1) + x_axis.unsqueeze(0)
        pair_x_axis = pair_x_axis[diag_mask].view(self.num_clusters, -1)
        pair_y_axis = y_axis.unsqueeze(1) + y_axis.unsqueeze(0)
        pair_y_axis = pair_y_axis[diag_mask].view(self.num_clusters, -1)
        
        # clamped_ldx = torch.clamp_min(-torch.log(masked_dx / pair_x_axis), min=0)
        # clamped_ldy = torch.clamp_min(-torch.log(masked_dy / pair_y_axis), min=0)
        
        clamped_ldx = torch.exp(torch.clamp_min(pair_x_axis * 2 - masked_dx, min=0) / torch.max(torch.sqrt(self.areas)) * 3)
        clamped_ldy = torch.exp(torch.clamp_min(pair_y_axis * 2 - masked_dy, min=0) / torch.max(torch.sqrt(self.areas)) * 3)
        
        overlap_penalty = \
            torch.sum(
                #overlap * \
                    (torch.diag(1 / self.rt_wh) @ clamped_ldx
                      +  torch.diag(self.rt_wh) @ clamped_ldy))
        
        dlc_h = \
            (distance_from_layout_center_horizontally := \
            torch.abs(x - self.half_width))
        dlc_v = \
            (distance_from_layout_center_vertically := \
            torch.abs(y - self.half_height))
        
        centripetal_penalty = \
            torch.sum(dlc_h + (self.half_width / 2) ** 2 / (dlc_h + EPSILON)) + \
            torch.sum(dlc_v + (self.half_height / 2) ** 2 / (dlc_v + EPSILON))
        
        obj = weighted_distance + l_overlap_penalty * overlap_penalty
        
        return obj, \
               {
                   "weighted_distance": weighted_distance,
                   "overlap_penalty": overlap_penalty,
                   "centripetal_penalty": centripetal_penalty,
               }

    def plot_layout(self, x, y, figname="layout"):
        self._plot_layout(x, y, rt_wh=self.rt_wh, figname=figname)        



class ABPlacer(ClusterPlacer): # AngleBasedPlacer
    EPSILON=1e-5
    def __init__(self, link_strength, macro_w, macro_h, layout_info, **kwargs):
        super(ABPlacer, self).__init__(layout_info, **kwargs)
            
        self.lnk_s = torch.from_numpy(link_strength).to(self.device)
        self.macro_w = torch.from_numpy(macro_w).to(self.device)
        self.macro_h = torch.from_numpy(macro_h).to(self.device)
        
        self.num_nodes = self.lnk_s.size(0)
        self.num_macros = self.macro_w.size(0)
        
        self.node_x = None
        self.node_y = None
        self.movable_macro_mask = None
        
        self.logger = logging.getLogger("ABPlace")
        
    
    def update_link_strength(self, link_strength):
        del self.lnk_s
        self.lnk_s = torch.from_numpy(link_strength).to(self.device)
        self.num_nodes = self.lnk_s.size(0)
    
    def __call__(self, node_x: np.ndarray, node_y: np.ndarray, movable_macro_mask: np.ndarray):
        node_x, node_y, movable_macro_mask = \
            node_x.copy(), node_y.copy(), movable_macro_mask.copy()
        if self.node_x is not None:
            del self.node_x
        self.node_x = torch.from_numpy(node_x).to(self.device)
        if self.node_x is not None:
            del self.node_y
        self.node_y = torch.from_numpy(node_y).to(self.device)
        if self.movable_macro_mask is not None:
            del self.movable_macro_mask
        self.movable_macro_mask = \
            torch.from_numpy(movable_macro_mask).bool().to(self.device)
    
    def place(self, theta=None, *, num_iterations=1000, learning_rate=8e-2, lr_decay=0.97, halo=.1, halo_type="ratio", l_overlap_penalty=1., return_type="theta", **kwargs):
        if theta is None:
            theta = torch.from_numpy(
                self.coordinate2theta(
                    self.node_x,
                    self.node_y,
                    self.movable_macro_mask
                )
            ).to(self.device)
            
        theta.requires_grad_(True)
        
        self.optimizer = optim.SGD(
            [theta], lr=learning_rate)
        
        self.scheduler = optim.lr_scheduler.StepLR(self.optimizer, step_size=1, gamma=lr_decay)
        
        tt = time.time()
        
        for it in range(num_iterations):
            converge = self.step(theta, it, halo=halo, halo_type=halo_type, l_overlap_penalty=l_overlap_penalty, **kwargs)
            if converge:
                break
        
        self.logger.info("angle-based placement takes %.3fms" % (time.time() - tt))

        if hasattr(self, f"return_{return_type}"):
            return getattr(self, f"return_{return_type}")(theta, **kwargs)
        else:
            raise NotImplementedError
            
    def return_theta(self, theta, **kwargs):
        return theta
    
    def return_coordinate(self, theta, /, ratio=1, **kwargs):
        return self.theta2coordinate(theta, ratio)
        
    def step(self, theta, it, /, halo=.1, halo_type="ratio", l_overlap_penalty=1., verbose=True, log_interval=100, **kwargs) -> bool:
        
        def obj_entries2content(it, obj, entries):
            f = lambda s, *args, **kwargs: s.format(*args, **kwargs)
            content = ", ".join([
                f("iteration {:4d}", it),
                f("Obj {:.6E}", obj.data),
                f("WeightedDistance {:.6E}", entries["weighted_distance"].data),
                f("OverlapPenalty {:.6E}", entries["overlap_penalty"].data),
                f("learning rate {:.6E}", self.optimizer.param_groups[0]["lr"]),
            ])
            return content
        
        self.optimizer.zero_grad()
        obj, entries = self.obj_fn(
            theta,
            halo=halo, halo_type=halo_type,
            l_overlap_penalty=l_overlap_penalty
        )
        
        if verbose and it == 0:
            self.logger.info(obj_entries2content(it, obj, entries))
        
        obj.backward()
        self.optimizer.step()
        self.scheduler.step()
        
        converge = False
        
        # TODO: criteria to detect convergence and stop early
        
        if verbose and ((it + 1) % log_interval == 0 or converge):
            with torch.no_grad():
                obj, entries = self.obj_fn(
                    theta,
                    halo=halo, halo_type=halo_type,
                    l_overlap_penalty=l_overlap_penalty
                )
            self.logger.info(obj_entries2content(it + 1, obj, entries))
        
        return converge
    
    def obj_fn(self, theta: torch.Tensor, /, halo=.1, halo_type="ratio", l_overlap_penalty=1.):
        ## utilities
        EPSILON = ABPlacer.EPSILON
        delta = lambda t1d0, t1d1: t1d0.unsqueeze(1) - t1d1.unsqueeze(0)
        summing = lambda t1d0, t1d1: t1d0.unsqueeze(1) + t1d1.unsqueeze(0)
        dmasked = (diagonal_masked := \
            lambda t: t[~torch.eye(t.size(0), dtype=bool)].view(t.size(0), -1))
        softabs = lambda t: torch.sqrt(t ** 2 + EPSILON ** 2) - EPSILON
        
        ## calculate objective item weighted_distance
        cos_theta, sin_theta = torch.cos(theta), torch.sin(theta)
        macro_x, macro_y = \
            self.half_width * cos_theta + self.half_width, \
            self.half_height * sin_theta + self.half_height
            
        im_lnk = (intermacro_link := \
            dmasked(self.lnk_s[self.movable_macro_mask]\
                              [:, self.movable_macro_mask]))
        im_delta_x = (intermacro_delta_x := \
            dmasked(delta(macro_x, macro_x)))
        im_delta_y = (intermacro_delta_y := \
            dmasked(delta(macro_y, macro_y)))
        
        mn_lnk = (macro_node_link := \
            self.lnk_s[self.movable_macro_mask][:, ~self.movable_macro_mask])
        mn_delta_x = (macro_node_delta_x := \
            delta(macro_x, self.node_x[~self.movable_macro_mask]))
        mn_delta_y = (macro_node_delta_y := \
            delta(macro_y, self.node_y[~self.movable_macro_mask]))
        
        im_dist = (intermacro_distance := \
            torch.sqrt(
                im_delta_x ** 2
              + im_delta_y ** 2
              + EPSILON ** 2) - EPSILON)
        im_wdist = (intermacro_weighted_distance := \
            torch.multiply(im_dist, im_lnk))
        
        mn_dist = (macro_node_distance := \
            torch.sqrt(
                mn_delta_x ** 2
              + mn_delta_y ** 2
              + EPSILON ** 2) - EPSILON)
        mn_wdist = (macro_node_weighted_distance := \
            torch.multiply(mn_dist, mn_lnk))
        
        weighted_distance = (torch.sum(im_wdist) + torch.sum(mn_wdist)) / 2
        
        ##  calculate objective item overlap_penalty
        macro_w = self.macro_w[self.movable_macro_mask[:self.num_macros]]
        macro_h = self.macro_h[self.movable_macro_mask[:self.num_macros]]
        macro_wp = (macro_w_pairwise := \
            summing(macro_w, macro_w))
        macro_hp = (macro_h_pairwise := \
            summing(macro_h, macro_h))
        
        if halo_type == "ratio":
            H_overlap = (horizontal_overlap := \
                torch.clamp_min(dmasked(macro_wp) * (1 + halo) - softabs(im_delta_x), 0))
            V_overlap = (vertical_overlap := \
                torch.clamp_min(dmasked(macro_hp) * (1 + halo) - softabs(im_delta_y), 0))
        else:
            raise NotImplementedError
        
        overlap_penalty = torch.sum(H_overlap * V_overlap) / 2
        
        obj = torch.tensor(0.0).to(self.device)
        obj += weighted_distance
        obj += overlap_penalty * l_overlap_penalty

        return obj, \
            {
                "weighted_distance": weighted_distance,
                "overlap_penalty": overlap_penalty,
            }
    
    def coordinate2theta(self, node_x: torch.Tensor, node_y: torch.Tensor, movable_macro_mask=None):
        EPSILON = ABPlacer.EPSILON
        if movable_macro_mask is None:
            movable_macro_mask = np.zeros(self.num_nodes, dtype=bool)
            movable_macro_mask[:self.num_macros] = 1
        
        movable_macro_mask = np.array(
            movable_macro_mask.detach().cpu(), dtype=bool)
        
        movable_macro_x, movable_macro_y = \
            np.array(node_x.detach().cpu())[movable_macro_mask], \
            np.array(node_y.detach().cpu())[movable_macro_mask]
        
        offset_x, offset_y = \
            movable_macro_x - self.half_width, movable_macro_y - self.half_height
        
        positive_mask = offset_x > 0
        floor = np.where(positive_mask, EPSILON, -self.half_width)
        ceil = np.where(positive_mask, self.half_width, -EPSILON)
        tan_theta = offset_y / np.clip(offset_x, floor, ceil)
        theta = np.arctan(tan_theta)
        
        return theta
    
    def theta2coordinate(self, theta: torch.Tensor, /, ratio=1.):
        W, H = self.width, self.height
        hW, hH = self.half_width, self.half_height
        t = theta.detach().cpu().numpy()
        real_x = hW * ratio * np.cos(t) + hW + self.xl
        real_y = hH * ratio * np.sin(t) + hH + self.yl
        return real_x, real_y

    def plot_distribution(self, theta, /, figname="distribution"):
        x = self.half_width * np.cos(theta.detach().cpu().numpy()) + self.half_width
        y = self.half_height * np.sin(theta.detach().cpu().numpy()) + self.half_height

        ellipse = Ellipse((self.half_width, self.half_height), self.width, self.height, color='b', fill=False)

        fig, ax = plt.subplots(figsize=(6, 6))
        ax.add_artist(ellipse)

        areas = (self.macro_w * self.macro_h)\
                .detach()\
                .cpu()\
                .numpy()[self.movable_macro_mask\
                         .detach()\
                         .cpu()\
                         .numpy()[:self.num_macros]]
        ax.scatter(x, y, np.sqrt(areas / np.pi), color='red', alpha=0.5)
        for idx, (_x, _y) in enumerate(zip(x, y)):
            ax.annotate(str(idx + 1), xy=(_x, _y), xytext=(_x, _y))

        ax.set_xlim(self.width * -0.1, self.width * 1.1)
        ax.set_ylim(self.height * -0.1, self.height * 1.1)
        ax.set_aspect('equal', 'box')

        # ax.axis('off')
        # fig.show()
        fig.savefig(f"{figname}.png")
        plt.close(fig)
    
    def plot_layout(self, xy=None, theta=None, *, figname="layout"):
        assert xy is not None or theta is not None
        if xy is not None:
            x, y = xy
        elif theta is not None:
            x, y = self.theta2coordinate(theta)
        self._plot_layout(x, y, figname=figname)
        
    def _plot_layout(self, x, y, /, print_lnk=False, figname="layout"):
        rect = Rectangle((self.xl, self.yl), self.width, self.height, color='b', fill=False)

        fig, ax = plt.subplots(figsize=(6, 6))
        ax.add_artist(rect)

        if isinstance(x, torch.Tensor):
            x = x.detach().cpu().numpy()
        if isinstance(y, torch.Tensor):
            y = y.detach().cpu().numpy()

        radius = np.ones(self.num_nodes) \
               * np.sqrt(self.width * self.height / 10000 / np.pi) * 2
        x_axis = radius.copy()
        y_axis = radius.copy()
        x_axis[:self.num_macros] = \
            self.macro_w.detach().cpu().numpy()[:self.num_macros]
        y_axis[:self.num_macros] = \
            self.macro_h.detach().cpu().numpy()[:self.num_macros]
        for idx, (_x, _y, _xa, _ya) in enumerate(zip(x, y, x_axis, y_axis)):
            if idx < self.num_macros:
                shape = Rectangle
                color = 'red'
            else:
                shape = Ellipse
                color = 'blue'
            ax.add_artist(
                shape((_x - _xa / 2, _y - _ya / 2), 
                      _xa, _ya, color=color, alpha=0.5))
            
        if print_lnk:
            lnk_s = self.lnk_s.detach().cpu().numpy()
            max_lnk_s = torch.max(self.lnk_s)
            for rx, ry, lnkarr in zip(x, y, self.lnk_s):
                for _rx, _ry, lnk in zip(x, y, lnkarr):
                    ax.add_line(Line2D([rx, _rx], [ry, _ry], linewidth=lnk / max_lnk_s, color='black'))

        ax.set_xlim(self.xl - self.width * 0.1, self.xh + self.width * 0.1)
        ax.set_ylim(self.yl - self.height * 0.1, self.yh + self.height * 0.1)
        ax.set_aspect('equal', 'box')

        fig.savefig(f"{figname}.png")
        plt.close(fig)