from abc import abstractmethod
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from matplotlib.lines import Line2D
import pdb
import math
from typing import Tuple

import logging
logger = logging.getLogger("MacroDistributor")

class BasicDistributor(object):
    def __init__(self, *args, **kwargs):
        pass

    def __call__(self,
        macro_c: np.ndarray,
        macro_w: np.ndarray,
        macro_h: np.ndarray,
        cluster_x: np.ndarray,
        cluster_y: np.ndarray,
        cluster_r: np.ndarray,
        *args, **kwargs
    ):
        self.macro_c   = macro_c
        self.macro_w   = macro_w
        self.macro_h   = macro_h
        self.cluster_x = cluster_x
        self.cluster_y = cluster_y
        self.cluster_r = cluster_r

        self.num_macros = self.macro_c.shape[0]

    @abstractmethod
    def distribute(self) -> Tuple[np.ndarray, np.ndarray]:
        pass


class NaiveDistributor(BasicDistributor):
    def __init__(self, divergence=0.99, **kwargs):
        super(NaiveDistributor, self).__init__()
        self.divergence = divergence

    def distribute(self) -> Tuple[np.ndarray, np.ndarray]:
        macro_x = np.random.normal(
            loc=self.cluster_x[self.macro_c],
            scale=self.cluster_r[self.macro_c] * self.divergence,
            size=self.num_macros
        ) - self.macro_w / 2
        macro_y = np.random.normal(
            loc=self.cluster_y[self.macro_c],
            scale=self.cluster_r[self.macro_c] * self.divergence,
            size=self.num_macros
        ) - self.macro_h / 2

        return macro_x, macro_y
    
class GridGuideDistributor(BasicDistributor):
    EPSILON = 1e-5
    def __init__(self, link_strength: np.ndarray, macro_w: np.ndarray, macro_h: np.ndarray, layout_info, grid_num_x=224, grid_num_y=224, bias=.1, bias_type="ratio", macro_halo_x=0, macro_halo_y=0, **kwargs):
        super(GridGuideDistributor, self).__init__()

        self.xl, self.xh, self.yl, self.yh = \
            layout_info["xl"], layout_info["xh"], \
            layout_info["yl"], layout_info["yh"]
        self.width, self.height = \
            self.xh - self.xl, self.yh - self.yl
        self.half_width, self.half_height = \
            self.width / 2, self.height / 2

        self.num_nodes = len(link_strength)
        self.num_macros = len(macro_w)
        self.lnk_s = link_strength
        self.macro_w = macro_w
        self.macro_h = macro_h
        self.grid_num_x = grid_num_x
        self.grid_num_y = grid_num_y
        if bias_type == "ratio":
            self.bias_w = bias * self.width
            self.bias_h = bias * self.height
            
        self.macro_halo_x = macro_halo_x
        self.macro_halo_y = macro_halo_y
        

    def update_link_strength(self, link_strength):
        self.num_nodes = len(link_strength)
        self.lnk_s = link_strength

    def __call__(self, node_x: np.ndarray, node_y: np.ndarray, unplaced_macro_mask: np.ndarray):
        self.node_x = node_x
        self.node_y = node_y
        self.unplaced_macro_mask = unplaced_macro_mask
        self.unplaced_macro_index = np.where(unplaced_macro_mask)[0]
        self.placed_macro_index = np.where(~unplaced_macro_mask)[0]
    
    def distribute(self, num2place) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        delta = lambda nparr1, nparr2: nparr1.reshape(-1, 1) - nparr2.reshape(1, -1)
        summing = lambda nparr1, nparr2: nparr1.reshape(-1, 1) + nparr2.reshape(1, -1)
        unplaced_x = self.node_x[:self.num_macros][self.unplaced_macro_mask]
        unplaced_y = self.node_y[:self.num_macros][self.unplaced_macro_mask]
        delta_x = delta(unplaced_x, unplaced_x)
        delta_y = delta(unplaced_y, unplaced_y)
        macro_pw = summing(self.macro_w[self.unplaced_macro_mask], 
                           self.macro_w[self.unplaced_macro_mask])
        macro_ph = summing(self.macro_h[self.unplaced_macro_mask], 
                           self.macro_h[self.unplaced_macro_mask])
        overlap_area = \
            np.sum(np.clip(macro_pw - np.abs(delta_x), 0, macro_pw) \
                 * np.clip(macro_ph - np.abs(delta_y), 0, macro_ph), axis=1)
        unplaced_lnk_s = self.lnk_s[:self.num_macros][self.unplaced_macro_mask]
        scores_lnk = np.sum(unplaced_lnk_s[:, :self.num_macros]\
                                          [:, self.unplaced_macro_mask], axis=1) \
                   + np.sum(unplaced_lnk_s[:, self.num_macros:], axis=1)
        # scores = -overlap_area
        scores = scores_lnk
        order = self.unplaced_macro_index[np.argsort(scores)]
        for index in order:
            succflag, new_x, new_y = \
                self.distribute_macro(
                    self.node_x[index],
                    self.node_y[index],
                    self.macro_w[index],
                    self.macro_h[index],
                    self.lnk_s[index]
                )
            if succflag:
                self.node_x[index] = new_x
                self.node_y[index] = new_y
                self.unplaced_macro_mask[index] = 0
                self.unplaced_macro_index = np.where(self.unplaced_macro_mask)[0]
                self.placed_macro_index = np.where(~self.unplaced_macro_mask)[0]
                num2place -= 1

            if num2place <= 0:
                break

        return self.node_x, self.node_y, self.unplaced_macro_mask

    def get_placed_mask(self):
        grid_size_x = self.width / self.grid_num_x
        grid_size_y = self.height / self.grid_num_y
        placed_mask = np.zeros((self.grid_num_x, self.grid_num_y))
        for index in self.placed_macro_index:
            haloed_macro_w = self.macro_w[index] + self.macro_halo_x
            haloed_macro_h = self.macro_h[index] + self.macro_halo_y
            xl = math.floor(
                (self.node_x[index] - haloed_macro_w / 2) / grid_size_x)
            xh = math.ceil(
                (self.node_x[index] + haloed_macro_w / 2) / grid_size_x)
            yl = math.floor(
                (self.node_y[index] - haloed_macro_h / 2) / grid_size_y)
            yh = math.ceil(
                (self.node_y[index] + haloed_macro_h / 2) / grid_size_y)
            placed_mask[max(xl, 0):min(xh + 1, self.grid_num_x),
                        max(yl, 0):min(yh + 1, self.grid_num_y)] = 1
        return placed_mask

    def generate_blockages(self, params):
        grid_size_x = self.width / self.grid_num_x
        grid_size_y = self.height / self.grid_num_y
        placed_mask = self.get_placed_mask()
        placed_grids = np.where(placed_mask)
        blockages = []
        for gx, gy in zip(*placed_grids):
            xl = (gx * grid_size_x + self.xl) / params.scale_factor + params.shift_factor[0]
            if gx + 1 < self.grid_num_x:
                xh = ((gx + 1) * grid_size_x + self.xl) / params.scale_factor + params.shift_factor[0]
            else:
                xh = self.xh / params.scale_factor + params.shift_factor[0]
            yl = (gy * grid_size_y + self.yl) / params.scale_factor + params.shift_factor[1]
            if gy + 1 < self.grid_num_y:
                yh = ((gy + 1) * grid_size_y + self.yl) / params.scale_factor + params.shift_factor[1]
            else:
                yh = self.yh / params.scale_factor + params.shift_factor[1]
            blockages.append((xl, yl, xh, yh))
        return blockages

    def plot_mask(self, mask, halo=0.5, figname="mask"):
        grid_size_x = self.width / self.grid_num_x
        grid_size_y = self.height / self.grid_num_y
        fig, ax = plt.subplots(figsize=(6, 6))
        xlist = []
        ylist = []
        for gx in range(self.grid_num_x):
            for gy in range(self.grid_num_y):
                color = 'green' if mask[gx, gy] else 'red'
                rx = (gx - 1) * grid_size_x * (1 + halo) + grid_size_x
                ry = (gy - 1) * grid_size_y * (1 + halo) + grid_size_y
                xlist.extend([rx, rx + grid_size_x])
                ylist.extend([ry, ry + grid_size_y])
                ax.add_artist(
                    Rectangle((rx, ry), grid_size_x, grid_size_y, color=color, alpha=0.5))
        
        xl, xh = min(xlist), max(xlist)
        yl, yh = min(ylist), max(ylist)
        ax.set_xlim(xl - (xh - xl) * 0.1, xh + (xh - xl) * 0.1)
        ax.set_ylim(yl - (yh - yl) * 0.1, yh + (yh - yl) * 0.1)
        ax.axis('off')
        ax.set_aspect('equal', 'box')

        fig.savefig(f"{figname}.pdf")
        plt.close(fig)

    def distribute_macro(self, x, y, w, h, lnk_s) -> Tuple[bool]:
        EPSILON = GridGuideDistributor.EPSILON
        haloed_w = w + self.macro_halo_x
        haloed_h = h + self.macro_halo_y
        grid_size_x = self.width / self.grid_num_x
        grid_size_y = self.height / self.grid_num_y
        offset_x, offset_y = x - self.half_width, y - self.half_height
        position_mask = np.zeros((self.grid_num_x, self.grid_num_y), dtype=bool)
        knml = offset_y / offset_x
        ktan = -offset_x / offset_y
        x_map = np.hstack(
            [np.arange(self.grid_num_x).reshape(-1, 1) for _ in range(self.grid_num_y)]
        ) * grid_size_x
        y_map = np.vstack(
            [np.arange(self.grid_num_y).reshape(1, -1) for _ in range(self.grid_num_x)]
        ) * grid_size_y
        
        gt = lambda a, b: a - b >  0
        le = lambda a, b: a - b <= 0

        f1 = le if knml > 0 else gt
        f2 = gt if knml > 0 else le
        f3 = gt if offset_y > 0 else le

        f1_map = f1(y_map, knml * (x_map - x + self.bias_w) + y)
        f2_map = f2(y_map, knml * (x_map - x - self.bias_w) + y)
        f3_map = f3(y_map, ktan * (x_map - x) + y)
        
        # self.plot_mask(f1_map, figname="f1")
        # self.plot_mask(f2_map, figname="f2")
        # self.plot_mask(f3_map, figname="f3")
        
        f1_map_ = x_map + self.bias_w + self.macro_halo_x > x if offset_x > 0 else x_map - self.bias_w - self.macro_halo_x <= x
        f2_map_ = y_map + self.bias_h + self.macro_halo_y > y if offset_y > 0 else y_map - self.bias_h - self.macro_halo_y <= y

        f1_map__ = np.ones_like(position_mask)
        f2_map__ = np.ones_like(position_mask)

        position_mask[
            np.logical_and(np.logical_and(f1_map_, f2_map_), f3_map)] = 1
        
        gw = math.ceil(haloed_w / grid_size_x)
        gh = math.ceil(haloed_h / grid_size_y)
        
        delta_xl =  0 if offset_x > 0 else gw
        delta_xh = gw if offset_x > 0 else  0
        delta_yl =  0 if offset_y > 0 else gh
        delta_yh = gh if offset_y > 0 else  0
        
        for index in self.placed_macro_index:
            haloed_macro_w = self.macro_w[index] + self.macro_halo_x
            haloed_macro_h = self.macro_h[index] + self.macro_halo_y
            xl = math.floor(
                (self.node_x[index] - haloed_macro_w / 2) / grid_size_x)
            xh = math.ceil(
                (self.node_x[index] + haloed_macro_w / 2) / grid_size_x)
            yl = math.floor(
                (self.node_y[index] - haloed_macro_h / 2) / grid_size_y)
            yh = math.ceil(
                (self.node_y[index] + haloed_macro_h / 2) / grid_size_y)
            position_mask[max(xl - delta_xl, 0): \
                          min(xh + delta_xh + 1, self.grid_num_x),
                          max(yl - delta_yl, 0): \
                          min(yh + delta_yh + 1, self.grid_num_y)] = 0

        valid_x, valid_y = np.where(position_mask)
        
        if valid_x.shape[0] <= 0:
            logger.warning("No valid position found in position mask.")
            return False, None, None

        # distance2periphery
        g1 = (lambda gx: self.grid_num_x - gx - 1) if offset_x > 0 else (lambda gx: gx)
        g2 = (lambda gy: self.grid_num_y - gy - 1) if offset_y > 0 else (lambda gy: gy)

        criterion_min = lambda gx, gy: min(g1(gx), g2(gy))

        mg1 = min([g1(gx) for gx in valid_x])
        mg2 = min([g2(gy) for gy in valid_y])
        criterion_product = lambda gx, gy: (g1(gx) - mg1 + EPSILON) * (g2(gy) - mg2 + EPSILON)
        
        dist2bound_x = self.grid_num_x - valid_x - 1 if offset_x > 0 else valid_x
        dist2bound_y = self.grid_num_x - valid_y - 1 if offset_y > 0 else valid_y
        pareto_mask = np.logical_or(np.vstack(
            [np.logical_or(dist2bound_x < dx, dist2bound_y < dy) for dx, dy in zip(dist2bound_x, dist2bound_y)]
        ), np.eye(valid_x.shape[0], dtype=bool))
        
        pareto_mask = np.all(pareto_mask, axis=0)
        pareto_front = list(zip(valid_x[pareto_mask], valid_y[pareto_mask]))
        
        criterion_pareto = lambda gx, gy: -1 if (gx, gy) in pareto_front else criterion_product(gx, gy)
        
        # criterion = criterion_product
        criterion = criterion_pareto
        
        candidates_0 = [(gx, gy, criterion(gx, gy))
                        for gx, gy in zip(valid_x, valid_y)]
        
        if len(candidates_0) <= 0:
            return False, None, None
        candidates_0.sort(key=lambda t: t[-1])

        best_score = candidates_0[0][-1]
        candidates_1 = [(gx, gy) for gx, gy, s in candidates_0 if s <= best_score + EPSILON ** 2]

        # grid_index2grid_corner_coordinate
        h1 = (lambda gx: (gx + 1) * grid_size_x) if offset_x > 0 else (lambda gx: gx * grid_size_x)
        h2 = (lambda gy: (gy + 1) * grid_size_y) if offset_y > 0 else (lambda gy: gy * grid_size_y)
        # anchor2center
        h3 = (lambda ax: ax - haloed_w) if offset_x > 0 else (lambda ax: ax)
        h4 = (lambda ay: ay - haloed_h) if offset_y > 0 else (lambda ay: ay)

        def get_score(_x, _y):
            distance = np.sqrt(np.abs(self.node_x - _x) ** 2 + np.abs(self.node_y - _y) ** 2)
            weighted_distance = lnk_s * distance
            weighted_distance[:self.num_macros][self.unplaced_macro_mask] = 0
            return np.sum(weighted_distance)

        candidates_2 = []
        for gx, gy in candidates_1:
            anchor_x, anchor_y = h1(gx), h2(gy)
            botlft_x, botlft_y = h3(anchor_x), h4(anchor_y)
            center_x, center_y = botlft_x + haloed_w / 2, botlft_y + haloed_h / 2
            score = get_score(center_x, center_y)
            candidates_2.append((center_x, center_y, score))
        
        candidates_2.sort(key=lambda t: t[-1])

        candidate_x, candidate_y, best_score = candidates_2[0]
        
        return True, candidate_x, candidate_y


        