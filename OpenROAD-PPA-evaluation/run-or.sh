designs=("ariane133" "ariane136" "black_parrot" "bp_be_top" "bp_fe_top" "bp_multi_top" "bp_quad" "swerv_wrapper")
design_nicknames=("ariane133" "ariane136" "bp" "bp_be" "bp_fe" "bp_multi" "bp_quad" "swerv_wrapper")

array_length=${#designs[@]}

for (( i=0; i<$array_length; i++ )); do
    design=${designs[$i]}
    design_nickname=${design_nicknames[$i]}
    make do-2_4_floorplan_macro DESIGN_CONFIG=./designs/nangate45/$design/config.mk
    make do-macroflow DESIGN_CONFIG=./designs/nangate45/$design/config.mk
done
