import os
    
def def2mp(def_path, ref_path, out_path):
    assert os.path.exists(def_path), f"file {def_path} not exists."
    assert os.path.exists(ref_path), f"file {ref_path} not exists."
    new_locations_filename = def_path
    standard_file = ref_path
    output_file = out_path
    
    def parse_new_locations(filename):
        new_locations = {}
        with open(filename, 'r') as file:
            lines = file.readlines()
            for i in range(len(lines)):
                if 'fakeram' in lines[i]:
                    macro_name = lines[i].strip().split(' ')[1]
                    if i + 1 < len(lines) and 'FIXED' in lines[i + 1]:
                        coords = lines[i + 1].split('(')[1].split(')')[0].strip().split()
                        new_locations[macro_name] = (float(coords[0]) / 2000, float(coords[1]) / 2000)
        return new_locations
    
    new_locations = parse_new_locations(new_locations_filename)
    
    def replace_locations_in_standard_file(standard_file, new_locations, output_file):
        with open(standard_file, 'r') as file:
            lines = file.readlines()
        
        with open(output_file, 'w') as file:
            for line in lines:
                parts = line.split(' -location ')
                macro_name = parts[0].split('-macro_name ')[1].split(' ')[0]
                if macro_name in new_locations:
                    new_location_str = "{:.3f} {:.3f}".format(new_locations[macro_name][0], new_locations[macro_name][1])
                    new_line = parts[0] + ' -location {' + new_location_str + '} -orientation R0\n'
                    file.write(new_line)
                else:
                    file.write(line)
                    
    replace_locations_in_standard_file(standard_file, new_locations, output_file)