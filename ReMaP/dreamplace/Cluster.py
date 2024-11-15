import networkit as nk
import pdb

class GraphBuilder:
    def __init__(self, placedb):
        self.net_names = placedb.net_names
        self.net_weights = placedb.net_weights
        self.net2pin_map = placedb.net2pin_map

        self.pin2node_map = placedb.pin2node_map
        self.node_names = placedb.node_names

        # Networkit 使用整数作为节点索引，创建一个带权图
        self.graph = nk.Graph(n=len(self.node_names), weighted=True, directed=False)

    def add_nodes(self):
        # 在 networkit 中，默认已经有了足够的节点，无需添加
        pass

    def add_edges(self):
        # 添加边，基于 nets 和 pins
        node_name_to_index = {name: i for i, name in enumerate(self.node_names)}

        for net_index, pins in enumerate(self.net2pin_map):
            weight = self.net_weights[net_index] if net_index < len(self.net_weights) else 1  # 使用默认权重1如果没有提供
            connected_nodes = set()
            for pin_id in pins:
                node_index = self.pin2node_map[pin_id]
                connected_nodes.add(node_index)  # 直接使用节点索引

            if len(connected_nodes) > 1:
                # 创建一个虚拟节点
                virtual_node_index = self.graph.addNode()
                # 连接虚拟节点到所有相关的节点
                for node_index in connected_nodes:
                    self.graph.addEdge(virtual_node_index, node_index, weight)
            else:
                # 直接连接这两个节点（如果只有两个节点的话）
                connected_nodes = list(connected_nodes)
                if len(connected_nodes) == 2:
                    self.graph.addEdge(connected_nodes[0], connected_nodes[1], weight)

    def build_graph(self):
        self.add_nodes()
        self.add_edges()
        return self.graph