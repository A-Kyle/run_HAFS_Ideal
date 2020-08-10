#!/bin/bash

set -ax

if [ ${gtype} != uniform ] && [ ${gtype} != stretch ] && \
   [ ${gtype} != nest ] && [ ${gtype} != regional ] ; then
  echo "Error (run_forecast): Bad grid type specified."
  exit 1
fi

exe_forecast=${EXEChafs}/hafs_forecast.x

if [ ! -e $exe_forecast ] ; then
  echo "Error (run_forecast): Could not find executable."
  exit 1
fi

mkdir -p ${forecast_dir} ${forecast_in} ${forecast_out} ${forecast_re} \
         ${forecast_work}

cd ${forecast_work}

# Link in the necessary inputs for the forecast.
ln -sf ${ic_dir}/*.nc ${forecast_in}/   # Link ICs from chgres
if [ ${gtype} = regional ]; then
  ln -sf ${bc_dir}/*.nc ${forecast_in}/   # Link BCs from chgres
fi

# Copy over fixed data to the runtime directory.
fix_am_dir=${FIXhafs}/fix_am
cp ${fix_am_dir}/global_solarconstant_noaa_an.txt  solarconstant_noaa_an.txt
cp ${fix_am_dir}/global_h2o_pltc.f77               global_h2oprdlos.f77
cp ${fix_am_dir}/global_sfc_emissivity_idx.txt     sfc_emissivity_idx.txt
cp ${fix_am_dir}/global_co2historicaldata_glob.txt co2historicaldata_glob.txt
cp ${fix_am_dir}/co2monthlycyc.txt                 co2monthlycyc.txt
cp ${fix_am_dir}/global_climaeropac_global.txt     aerosol.dat
cp ${fix_am_dir}/ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77 global_o3prdlos.f77
cp ${fix_am_dir}/global_glacier.2x2.grb .
cp ${fix_am_dir}/global_maxice.2x2.grb .
cp ${fix_am_dir}/RTGSST.1982.2012.monthly.clim.grb .
cp ${fix_am_dir}/global_snoclim.1.875.grb .
cp ${fix_am_dir}/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb .
cp ${fix_am_dir}/global_albedo4.1x1.grb .
cp ${fix_am_dir}/CFSR.SEAICE.1982.2012.monthly.clim.grb .
cp ${fix_am_dir}/global_tg3clim.2.6x1.5.grb .
cp ${fix_am_dir}/global_vegfrac.0.144.decpercent.grb .
cp ${fix_am_dir}/global_vegtype.igbp.t1534.3072.1536.rg.grb .
cp ${fix_am_dir}/global_soiltype.statsgo.t1534.3072.1536.rg.grb .
cp ${fix_am_dir}/global_soilmgldas.t1534.3072.1536.grb .
cp ${fix_am_dir}/seaice_newland.grb .
cp ${fix_am_dir}/global_shdmin.0.144x0.144.grb .
cp ${fix_am_dir}/global_shdmax.0.144x0.144.grb .
cp ${fix_am_dir}/global_slope.1x1.grb .
cp ${fix_am_dir}/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb .

for file in `ls ${fix_am_dir}/fix_co2_proj/global_co2historicaldata* ` ; do
  # this sed expression truncates the "global_" prefix on the list of files.
  cp $file $(echo $(basename $file) |sed -e "s/global_//g")
done

if [ ${gtype} != regional ] ; then
  glob_pes=$(( ${glob_layoutx} * ${glob_layouty} * 6 ))
  # Link grid, orog, mosaic data to the input directory.
  tile=1
  while [ $tile -le ${ntiles} ]; do
    ln -sf ${grid_out_dir}/${grid_name}.tile${tile}.nc \
            ${forecast_in}/${grid_name}.tile${tile}.nc
    ln -sf ${grid_out_dir}/${oro_name}.tile${tile}.nc \
            ${forecast_in}/oro_data.tile${tile}.nc
    tile=`expr $tile + 1 `
  done
  ln -sf ${grid_out_dir}/${mosaic_name}.nc ${forecast_in}/grid_spec.nc

  cd ${forecast_in}
  # Rename atmos files to gfs. Has to be like this for model
  i=1
  while [ $i -le 6 ]; do
    mv atm_data.tile${i}.nc gfs_data.tile${i}.nc
    i=`expr $i + 1 `
  done
fi

if [ ${gtype} = uniform ] ; then
  cd ${forecast_work}
  # NOTE: The number of tasks should account for tasks in writing,
  #       and running the global domain.
#  ntasks=$(( ${glob_pes} + (${write_groups} * ${write_tasks_per_group}) ))
#  cat model_configure.tmp | sed s/NTASKS/${ntasks}/ | sed s/YR/${year}/ | \
#      sed s/MN/${month}/ | sed s/DY/${day}/ | sed s/H_R/${hour}/ | \
#      sed s/NHRS/${num_hours}/ | sed s/NTHRD/${num_threads}/ | \
#      sed s/NCNODE/${cores_per_node}/ | \
#      sed s/_dt_atmos_/${dt}/ | \
#      sed s/_restart_interval_/${restart_interval}/ | \
#      sed s/_quilting_/${quilting}/ | \
#      sed s/_write_groups_/${write_groups}/ | \
#      sed s/_write_tasks_per_group_/${write_tasks_per_group}/ | \
#      sed s/_app_domain_/${gtype}/ | \
#      sed s/_OUTPUT_GRID_/${output_grid}/ | \
#      sed s/_CEN_LON_/${output_grid_cen_lon}/ | \
#      sed s/_CEN_LAT_/${output_grid_cen_lat}/ | \
#      sed s/_LON1_/${output_grid_lon1}/ | \
#      sed s/_LAT1_/${output_grid_lat1}/ | \
#      sed s/_LON2_/${output_grid_lon2}/ | \
#      sed s/_LAT2_/${output_grid_lat2}/ | \
#      sed s/_DLON_/${output_grid_dlon}/ | \
#      sed s/_DLAT_/${output_grid_dlat}/ \
#      >  model_configure

elif [ ${gtype} = nest ]; then
  # The next 4 links are a hack GFDL requires for running a nest
  # The two grid file links may be redundant.
  ln -sf ${grid_name}.tile7.nc grid.nest02.tile7.nc
  ln -sf ${grid_name}.tile7.nc ${grid_name}.nest02.tile7.nc
  ln -sf oro_data.tile7.nc oro_data.nest02.tile7.nc
  ln -sf atm_data.tile7.nc gfs_data.nest02.tile7.nc
  ln -sf sfc_data.tile7.nc sfc_data.nest02.tile7.nc
  # What about tile 8 (a second nest)?
  # Perhaps this?
  ln -sf ${grid_name}.tile8.nc grid.nest03.tile8.nc
  ln -sf ${grid_name}.tile8.nc ${grid_name}.nest03.tile8.nc
  ln -sf oro_data.tile8.nc oro_data.nest03.tile8.nc
  ln -sf atm_data.tile8.nc gfs_data.nest03.tile8.nc
  ln -sf sfc_data.tile8.nc sfc_data.nest03.tile8.nc

  cd ${forecast_work}

  # NOTE: The number of tasks should account for tasks in writing,
  #       running the global domain, and all nested domains.
  #       IN THIS TEST, the number of tasks for each nested domain
  #       are CONSTANT, but should be allowed to be variable.
  ntasks=$(( ${glob_pes} + (${write_groups} * ${write_tasks_per_group}) ))
  ntasks=$(( ${ntasks} + (2 * ${layoutx} * ${layouty} ) )) # THIS IS JUST FOR TESTING MSN.
  cat model_configure.tmp | sed s/NTASKS/${ntasks}/ | sed s/YR/${year}/ | \
      sed s/MN/${month}/ | sed s/DY/${day}/ | sed s/H_R/${hour}/ | \
      sed s/NHRS/${num_hours}/ | sed s/NTHRD/${num_threads}/ | \
      sed s/NCNODE/${cores_per_node}/ | \
      sed s/_dt_atmos_/${dt}/ | \
      sed s/_restart_interval_/${restart_interval}/ | \
      sed s/_quilting_/${quilting}/ | \
      sed s/_write_groups_/${write_groups}/ | \
      sed s/_write_tasks_per_group_/${write_tasks_per_group}/ | \
      sed s/_app_domain_/${gtype}/ | \
      sed s/_OUTPUT_GRID_/${output_grid}/ | \
      sed s/_CEN_LON_/${output_grid_cen_lon}/ | \
      sed s/_CEN_LAT_/${output_grid_cen_lat}/ | \
      sed s/_LON1_/${output_grid_lon1}/ | \
      sed s/_LAT1_/${output_grid_lat1}/ | \
      sed s/_LON2_/${output_grid_lon2}/ | \
      sed s/_LAT2_/${output_grid_lat2}/ | \
      sed s/_DLON_/${output_grid_dlon}/ | \
      sed s/_DLAT_/${output_grid_dlat}/ \
      >  model_configure
fi

#-------------------------------------------------------------------
# Run the forecast
#-------------------------------------------------------------------

${MPIRUN} $exe_forecast 1>out.C${res} 2>err.C${res}
#${MPIRUN} $exe_forecast
if [ $? -ne 0 ]; then
  echo "Error (run_forecast): hafs_forecast returned non-zero status."
  exit 1
fi

exit 0
