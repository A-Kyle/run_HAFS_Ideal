#!/bin/bash

# include settings
. settings_sys.sh
. ${WORKhafs}/settings_grid.sh
. ${WORKhafs}/settings_chgres.sh
. ${WORKhafs}/settings_forecast.sh

set -ax

if [ ${gtype} != uniform ] && [ ${gtype} != stretch ] && \
   [ ${gtype} != nest ] && [ ${gtype} != regional ] ; then
  echo "Error: Bad grid type specified."
  exit 1
fi

mkdir -p ${forecast_dir} ${forecast_in} ${forecast_out} ${forecast_re} \
         ${forecast_work}

cd ${forecast_work}

if [ ${gtype} = uniform ]; then
  # Copy or set up files data_table, diag_table, field_table,
  #   input.nml, input_nest02.nml, model_configure, and nems.configure
  namelist_dir="${PARMhafs}/forecast/uniform"
  cp ${namelist_dir}/data_table .
  cp ${namelist_dir}/diag_table.tmp .
  cp ${namelist_dir}/field_table .
  cp ${namelist_dir}/input.nml.tmp .
  cp ${namelist_dir}/model_configure.tmp .
  cp ${namelist_dir}/nems.configure .

  # Copy xml file for the global nest ccpp physics suite
  ccpp_suite_dir="${HOMEhafs}/sorc/hafs_forecast.fd/FV3/ccpp/suites"
  ccpp_suite_glob_xml="${ccpp_suite_dir}/suite_${ccpp_suite_glob}.xml"
  cp ${ccpp_suite_glob_xml} .

  glob_pes=$(( ${glob_layoutx} * ${glob_layouty} * 6 ))

  # Replace placeholder values in the input namelist template
  # to create coarse-grid input namelist for the forecast
  sed -e "s/_fhmax_/${num_hours}/g" \
      -e "s/_ccpp_suite_/${ccpp_suite_glob}/g" \
      -e "s/_layoutx_/${glob_layoutx}/g" \
      -e "s/_layouty_/${glob_layouty}/g" \
      -e "s/_npx_/${glob_npx}/g" \
      -e "s/_npy_/${glob_npy}/g" \
      -e "s/_npz_/${npz}/g" \
      -e "s/_target_lat_/${target_lat}/g" \
      -e "s/_target_lon_/${target_lon}/g" \
      -e "s/_stretch_fac_/${stretch_fac}/g" \
      -e "s/_glob_pes_/${glob_pes}/g" \
      -e "s/_levp_/${levs}/g" \
    input.nml.tmp > input.nml

  # NOTE: The number of tasks should account for tasks in writing,
  #       running the global domain, and all nested domains.
  #       IN THIS TEST, the number of tasks for each nested domain
  #       are CONSTANT, but should be allowed to be variable.
  ntasks=$(( ${glob_pes} + (${write_groups} * ${write_tasks_per_group}) ))
  cat model_configure.tmp | sed s/NTASKS/${ntasks}/ | sed s/YR/${year}/ | \
      sed s/MN/${month}/ | sed s/DY/${day}/ | sed s/H_R/${hour}/ | \
      sed s/NHRS/${num_hours}/ | sed s/NTHRD/${num_threads}/ | \
      sed s/NCNODE/${cores_per_node}/ | \
      sed s/_dt_atmos_/${dt}/ | \
      sed s/_restart_interval_/${restart_interval}/ | \
      sed s/_quilting_/${quilting}/ | \
      sed s/_write_groups_/${write_groups}/ | \
      sed s/_write_tasks_per_group_/${write_tasks_per_group}/ | \
      sed s/_app_domain_/${app_domain}/ | \
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

elif [ ${gtype} = nest ]; then
  # Copy or set up files data_table, diag_table, field_table,
  #   input.nml, input_nest02.nml, model_configure, and nems.configure
  # TEST: going to try using atmos_sos in diag_table for multinest output
  parm_nest_dir="${PARMhafs}/forecast/multinest"
  cp ${parm_nest_dir}/data_table .
  cp ${parm_nest_dir}/diag_table.multi diag_table.tmp
#  cp ${parm_nest_dir}/diag_table.tmp .
  cp ${parm_nest_dir}/field_table .
  cp ${parm_nest_dir}/input.nml.tmp .
  cp ${parm_nest_dir}/input_nest02.nml.tmp .
  cp ${parm_nest_dir}/model_configure.tmp .
  cp ${parm_nest_dir}/nems.configure .

  # Copy xml file for the global nest ccpp physics suite
  ccpp_suite_dir="${HOMEhafs}/sorc/hafs_forecast.fd/FV3/ccpp/suites"
  ccpp_suite_glob_xml="${ccpp_suite_dir}/suite_${ccpp_suite_glob}.xml"
  cp ${ccpp_suite_glob_xml} .

  ndomain=$(( ${num_nests} + 1 )) # +1 for the global grid
  glob_pes=$(( ${glob_layoutx} * ${glob_layouty} * 6 ))

  # Calculate the number of PEs for the nests
  # NOTE: PEs for nest 1 and 2 are equal only
  #       in THIS TEST. For the workflow, we'll need
  #       to account for a variable number of PEs
  #       across grids.
  nest_pes=$(( ${layoutx} * ${layouty} ))
  nest_pes="${nest_pes},${nest_pes}"
  # nest_pes="${nest_pes_nest1},${nest_pes_nest2}, ..."

  # Replace placeholder values in the input namelist template
  # to create coarse-grid input namelist for the forecast
  sed -e "s/_fhmax_/${num_hours}/g" \
      -e "s/_ccpp_suite_/${ccpp_suite_glob}/g" \
      -e "s/_layoutx_/${glob_layoutx}/g" \
      -e "s/_layouty_/${glob_layouty}/g" \
      -e "s/_npx_/${glob_npx}/g" \
      -e "s/_npy_/${glob_npy}/g" \
      -e "s/_npz_/${npz}/g" \
      -e "s/_target_lat_/${target_lat}/g" \
      -e "s/_target_lon_/${target_lon}/g" \
      -e "s/_stretch_fac_/${stretch_fac}/g" \
      -e "s/_ngrids_/${ndomain}/g" \
      -e "s/_glob_pes_/${glob_pes}/g" \
      -e "s/_nest_pes_/${nest_pes}/g" \
      -e "s/_levp_/${levs}/g" \
    input.nml.tmp > input.nml

  # Do the same thing but for the first nested-grid.
  ccpp_suite_nest_xml="${ccpp_suite_dir}/suite_${ccpp_suite_nest}.xml"
  cp ${ccpp_suite_nest_xml} .

  ioffset=$(( (${istart_nest}-1)/2 + 1))
  joffset=$(( (${jstart_nest}-1)/2 + 1))

  sed -e "s/_fhmax_/${num_hours}/g" \
      -e "s/_ccpp_suite_/${ccpp_suite_nest}/g" \
      -e "s/_layoutx_/${layoutx}/g" \
      -e "s/_layouty_/${layouty}/g" \
      -e "s/_npx_/${npx}/g" \
      -e "s/_npy_/${npy}/g" \
      -e "s/_npz_/${npz}/g" \
      -e "s/_target_lat_/${target_lat}/g" \
      -e "s/_target_lon_/${target_lon}/g" \
      -e "s/_stretch_fac_/${stretch_fac}/g" \
      -e "s/_refinement_/${refine_ratio}/g" \
      -e "s/_ioffset_/${ioffset}/g" \
      -e "s/_joffset_/${joffset}/g" \
      -e "s/_ngrids_/${ndomain}/g" \
      -e "s/_glob_pes_/${glob_pes}/g" \
      -e "s/_nest_pes_/${nest_pes}/g" \
      -e "s/_levp_/${levs}/g" \
    input_nest02.nml.tmp > input_nest02.nml

  # Once more for the second nest.
  # In a workflow, this could probably be handled
  # cleanly in a for-loop that iterates through
  # for each nest.
  ioffset=$(( (${istart_nest_2}-1)/2 + 1))
  joffset=$(( (${jstart_nest_2}-1)/2 + 1))

  sed -e "s/_fhmax_/${num_hours}/g" \
      -e "s/_ccpp_suite_/${ccpp_suite_nest}/g" \
      -e "s/_layoutx_/${layoutx}/g" \
      -e "s/_layouty_/${layouty}/g" \
      -e "s/_npx_/${npx}/g" \
      -e "s/_npy_/${npy}/g" \
      -e "s/_npz_/${npz}/g" \
      -e "s/_target_lat_/${target_lat}/g" \
      -e "s/_target_lon_/${target_lon}/g" \
      -e "s/_stretch_fac_/${stretch_fac}/g" \
      -e "s/_refinement_/${refine_ratio}/g" \
      -e "s/_ioffset_/${ioffset}/g" \
      -e "s/_joffset_/${joffset}/g" \
      -e "s/_ngrids_/${ndomain}/g" \
      -e "s/_glob_pes_/${glob_pes}/g" \
      -e "s/_nest_pes_/${nest_pes}/g" \
      -e "s/_levp_/${levs}/g" \
    input_nest02.nml.tmp > input_nest03.nml

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
      sed s/_app_domain_/${app_domain}/ | \
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

# Generate diag_table, model_configure from their templates
# Note to self: What does this namelist do? What are these variables?
echo ${year}${month}${day}.${hour}Z.C${res}.32bit.non-hydro
echo ${year} ${month} ${day} ${hour} 0 0
cat > temp <<EOF
  ${year}${month}${day}.${hour}Z.C${res}.32bit.non-hydro
  ${year} ${month} ${day} ${hour} 0 0
EOF

cat temp diag_table.tmp > diag_table

exit 0
