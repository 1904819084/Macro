import networkit as nk
import pdb

class GraphBuilder:
    def __init__(self, placedb):
        self.net_names = placedb.net_names
        self.net_weights = placedb.net_weights
        self.net2pin_map = placedb.net2pin_map

        self.pin2node_map = placedb.pin2node_map
        self.node_names = placedb.node_names

        # build graph
        self.graph = nk.Graph(n=len(self.node_names), weighted=True, directed=False)

    def add_nodes(self):
        pass

    def add_edges(self):
        for net_index, pins in enumerate(self.net2pin_map):
            weight = self.net_weights[net_index] if net_index < len(self.net_weights) else 1
            connected_nodes = set()
            for pin_id in pins:
                node_index = self.pin2node_map[pin_id]
                connected_nodes.add(node_index)

            if len(connected_nodes) > 1:
                # create virtual node
                virtual_node_index = self.graph.addNode()
                for node_index in connected_nodes:
                    self.graph.addEdge(virtual_node_index, node_index, weight)
            else:
                connected_nodes = list(connected_nodes)
                if len(connected_nodes) == 2:
                    self.graph.addEdge(connected_nodes[0], connected_nodes[1], weight)

    def build_graph(self):
        self.add_nodes()
        self.add_edges()
        return self.graph
    
