cd step_overshoot/

for M in 2 5
do
  for Z in 0.0140 0.0014
  do
    for fov in 0.20 0.40
    do
      for f0ov in 0.001 0.005 0.010
      do
        folder=M"$M"_Z"$Z"_fov"$fov"_f0ov"$f0ov"
#        mv "$folder"/M\*\*\*\*_Z"$Z"_fov"$fov"_f0ov"$f0ov".mod "$folder"/M"$M".00_Z"$Z"_fov"$fov"_f0ov"$f0ov".mod
        #ls $folder
        mv "$folder"/M" $M".0_Z"$Z"_fov"$fov"0_f0ov"$f0ov".mod "$folder"/M"$M".0_Z"$Z"_fov"$fov"0_f0ov"$f0ov".mod
      done
    done
  done
done
