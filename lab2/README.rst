============================================================
Monday Lab 2: Overshooting during core helium burning (CHeB)
============================================================

Preparation
===========

Now we are interested in studying how stars with and without core 
overshooting evolve during the CHeB and which impact it has. 

As a first step, we copy the folder from Lab1 and name it Lab2.
You can do this by hand or run in your terminal::

	cp -r lab1 lab2

Before we start modifying the inlists such that we can model the 
further evolution of our 5Msun star, lets clean up the directory
and delete not needed files from our previous runs, such as the 
directories LOGS, photos, and png::

	./clean
	rm -r LOGS photos png

In the previous Lab1 we have calculated a 5Msun model with 
step overshooting having f=0.030 and f0=0.005 until core-hydrogen
depletion. The model should be saved as ``M5_Z0014_fov030_f0ov0005.mod``
and should be still in your lab2 folder. To save computation time, 
and to avoid calculating the evolution to the TAMS several times,
we will load the saved model every time when we will explore 
different physical settings. 

inlist_project: star_job
------------------------

To load a saved model, we need to modify our *inlist_project* 
in the *star_job* section. Since we do not need to start with
a pre-main-sequence model anymore, we need to delete the following
lines::

  ! begin with a pre-main sequence model
    create_pre_main_sequence_model = .true.
  ! reducing the number of relaxation steps to decrease computation time
    pre_ms_relax_num_steps = 100

We also do no longer need to save the model at the end of the run, 
meaning that we can also delete the following lines::

  ! save a model and photo at the end of the run
    save_model_when_terminate = .true.
    save_photo_when_terminate = .true.
    save_model_filename = 'M5_Z0014_fov030_f0ov0005.mod'

Furthermore, since we do want to start from a previously saved
model, we do not want to fix the initial timesteps and thus 
remove the lines:: 

  ! Set the initial time step to 1000 years
    set_initial_dt = .true.
    years_for_initial_dt = 1d3
    
Now, we need to add lines that tell MESA to load a saved model.
Can you go to the MESA website and search for commands that allow
us to load a saved model?

* HINT_1: Look in the *star_job* panel under *References and Defaults*
here: `https://docs.mesastar.org/en/latest/reference/star_job.html 
<https://docs.mesastar.org/en/latest/reference/star_job.html>`

* HINT_2: Can you find on the website any content that is related to 
**load** something?

* SOLUTION: Add to your *star_job* section in the *inlist_project* 
the following lines::

  ! loading the pre-saved 5Msun model
    load_saved_model = .true.
    load_model_filename = 'M5_Z0014_fov030_f0ov0005.mod'


inlist_project: controls
------------------------

Now that we are done with modifying the *star_job* section, we 
also need to check if there are any controls that will cause 
issues when loading and running the model. 

The first controls that can be removed are, the ones defining 
the initial conditions at the beginning of the evolution::
	
  ! starting specifications
    initial_mass = 5 ! in Msun units

  ! Set initial fractions according to Galactic enrichtment law
  ! Primordial helium abundance (Aver et al. 2021)
  ! Galactic enrichment ratio. Calibrated by requiring that for solar (Xini, Yini, Zini) = (0.710, 0.276, 0.014), NP+12
    initial_z = 0.014 ! initial metal mass fraction
    initial_y = 0.276002 ! = 0.2453d0 + 2.193d0 * initial_z
    
Moreover, we should change our stopping condition. In Lab 1, we
were only interested in the evolution until the TAMS. But now we
want to go to the end of core helium burning (CHeB). Can you find
a option on the MESA website that will stop the model at the 
TACHeB? Replace the old stopping condition by the new one.

* HINT_1: Look in the *controls* panel under *References and Defaults*
here: `https://docs.mesastar.org/en/latest/reference/controls.html
<https://docs.mesastar.org/en/latest/reference/controls.html>`

* HINT_2: Can you find on the website any content that is related to 
**stop** at a specific **phase**?

* SOLUTION: Replace the lines::

  ! stop when the center mass fraction of h1 drops below this limit
    xa_central_lower_limit_species(1) = 'h1'
    xa_central_lower_limit(1) = 1d-3

with::

  ! stop at the end of core helium burning 
    stop_at_phase_TACHeB = .true.

In principle your model should now be able to run until helium is
depleted in the core. But before we run the model, lets add some
more physics that is needed during the later evolutionary stages.

After the main-sequence evolution in stars regions 
will appear that are stable against the Schwarzschild criterion
but not the Ledoux criterion. These regions are thought to 
undergo slow semiconvective mixing. To include semiconvection 
in our models, we need to turn on the Ledoux criterion and 
define the efficiency of the mixing process::

  ! mixing
    use_Ledoux_criterion = .true.
    alpha_semiconvection = 1d0
    
Furthermore, stars will start to burn hydrogen in their envelope,
leading to the formation of an outwards increasing mean molecular 
weight. In stars in the regions stable to convection but with such
a gradient, there will be some mixing in the form of thermohaline 
mixing. To create a more realistic model, lets turn this option 
on in the *controls* section by adding::

  ! mixing
    thermohaline_coeff = 1d0
    
Also massive stars will evolve into red supergiants (RSG) or 
Wolf-Rayet (WR) stars where the current wind mass-loss rates 
are no longer applicable. MESA has different options to choose
pre-included mass-loss recipes for the different evolutionary
phases, as well as contains a general recipe that uses a set
of predefined mass-loss recipes called the *Dutch* recipe. For
simplicity let us use the *Dutch* mass-loss recipe, for your 
science case you might want to choose a different one. To switch
the mass-loss recipe, we can simply replace the following lines::

  ! wind 
    hot_wind_scheme = 'Vink'
    Vink_scaling_factor = 0.3d0 ! --> Puls, J., (2015, IAU3017 proceeding), Bjorklund et al. 2020

by these lines::

  ! wind
    hot_wind_scheme = 'Dutch'
    Dutch_scaling_factor = 1d0
    
adding a new inlist file: inlist_extra
--------------------------------------

In the next step, we want to vary the input parameters of our
model calculations and the output files where the LOGS and png
files are saved. Because it can be quite messy, adding and
editing the various parameters in the *inlist_project* and 
*inlist_pgstar* at the same time, lets create a new inlist, 
in which we only have the controls that we want to edit for
both files. To do that, we can add in the *controls* 
section of the *inlist_project* file the following lines::

  ! adding an external file where we can add additional controls
    read_extra_controls_inlist(1) = .true.
    extra_controls_inlist_name(1) = 'inlist_extra'
    
and in the *pgstar* section in *inlist_pgstar*::

  ! adding an external file where we can add additional controls
    read_extra_pgstar_inlist(1) = .true.
    extra_pgstar_inlist_name(1) = 'inlist_extra'
    
This tells MESA to also read controls and pgstar inputs from
the file *inlist_extra*. So far this file does not exist, so 
lets create it. In Linux you can do that by typing in your 
terminal::

	touch inlist_extra
	
To tell MESA where to read the new controls, we need to add 
in *inlist_extra* a controls and a pgstar section::

	&controls
	  ! Here we can add our controls
	   
	/ ! end of controls namelist
	
	&pgstar
	  ! Here we can edit stuff related to pgstar
	  
	/ ! end of star_job namelist
	
As a first run, we want to calculate the 5Msun model until
core helium depletion without including core overshoot. To 
be able to compare the output between the different models,
lets create for each run a separate output folder for the 
LOGS and the png files. To change the default storage folders
we can add in the *controls* section in the *inlist_extra*::

  ! change the LOGS directory
    log_directory = 'output_no_overshoot/LOGS'

and in the *pgstar* section in the *inlist_extra*::

  ! change the png directory
    Grid1_file_dir = 'output_no_overshoot/png' 
    
Running different models until TACHeB
=====================================

Core helium burning without convection
--------------------------------------
    
Before we start running the model without core overshooting
during core helium burning. Think about what you would expect.
Should the core grow, stay at the same size, or even receed 
and why do you think so?
    
Finally it is time to run the model! Go to your terminal,
load and run MESA::

	./clean && ./mk
	./rn
	
Look at your pgstar output. Especially at the upper right
plot depicting how much the convective core grows in mass.
How does the core evolve? Was it as you expected? Can you 
figure out why the core behaves as it does?

* HINT_1: Compared to the first lab, we added additional 
physics related to mixing. Can you identify the new
mixing regions in the Kippenhahn diagram in the lower 
left plot? Can they have an impact on the core mass?

* SOLUTION: Because we include in our model thermohaline and
semiconvective mixing, the additional helium produced 
in the hydrogen shell burning layers can be mixed into
the core fueling it with additional material and leading 
to an increase in its mass.

Core helium burning with weak step overshooting
-----------------------------------------------

Now lets add some overshooting on top of the helium burning
core to see how it impacts the evolution. As a first model, 
lets start with a weak step overshooting as used in lab1,
namely f_ov = 0.1 and f0_ov = 0.005. In lab1, we added 
overshooting on the top of the hydrogen burning core by 
using the following lines::

  ! mixing
     overshoot_scheme(1) = 'step'
     overshoot_zone_type(1) = 'burn_H'
     overshoot_zone_loc(1) = 'core'
     overshoot_bdy_loc(1) = 'top'
     overshoot_f(1) = 0.3
     overshoot_f0(1) = 0.005

Lets copy these lines and add them in the *controls* section 
in *inlist_extra*. Can you figure out how we need to modify
them to tell MESA that we want a second overshooting region
on top of the helium burning core?

* HINT_1: Since the first overshooting scheme is already used 
in the first set ``(1)`` we need to change them to ``(2)``
for all controls.

* HINT_2: Is the overshooting zone still the correct one? Can
you find on the website other options where to allow 
overshooting? Check the controls for overshooting on
`https://docs.mesastar.org/en/latest/reference/controls.html
<https://docs.mesastar.org/en/latest/reference/controls.html>`.

* HINT_3: Do not forget to change the f_ov and f0_ov values.

* SOLUTION: In the end you should have in the *controls* section
of your *inlist_extra* lines that are similar to::

  ! mixing
     overshoot_scheme(2) = 'step'
     overshoot_zone_type(2) = 'burn_He'
     overshoot_zone_loc(2) = 'core'
     overshoot_bdy_loc(2) = 'top'
     overshoot_f(2) = 0.1
     overshoot_f0(2) = 0.005

Before we start the model, remember to change the output files
such that we are not overwriting the outputs from the last run.
We can do that in the *inlist_extra* by overwriting the directory
commands with::

  ! change the LOGS directory
    log_directory = 'output_overshoot_fov0p1_f0ov0p005/LOGS'
    
  ! change the png directory
    Grid1_file_dir = 'output_overshoot_fov0p1_f0ov0p005/png' 

What do you expect to happen now? Will the core grow, stay at
the same level, or receed? What happens to the semiconvective
layers that were on top of the convective core? Will they still
be there?

Okay we are ready to go, lets run the model::

	./rn
	
Look again at how the convective core grows in mass. Does it
fit your expectations? Compare the maximum mass of the 
convective core to the case without overshooting. To do that
you can have a look at your pgstar files saved in 
``output_no_overshoot/png``. Are the maximum masses similar
or different and why?

* SOLUTION: Overshooting is acting on much shorter timescale
than semiconvection. Even with a small overshooting on the core
we can let the core grow quite quickly.

If you look at the upper right plot, showing the evolution 
of the growing core, you should see some pulses where the core
mass grows and receeds again. That is strange. At the model
numbers where these pulses occur, can you see something happening
in the structure of the star in the Kippenhahn diagram?

* SOLUTION: You should see that a convective region forms 
directly on top of the overshooting region. That is strange, 
isn't it? Lets ignore it for now and test if it still appears
when using a more efficient overshooting.


Core helium burning with strong step overshooting
-------------------------------------------------

Now, lets add some strong step overshoot during core helium 
burning to see how it impacts the convective core mass. 
Following Lab1, lets now use the step overshoot for massive
stars f_ov=0.3. To include it in MESA we need to change the 
line for the f_ov in *inlist_extra*::

     overshoot_f(2) = 0.3
     
Before you run you model, do not forget to change the output
paths to::

  ! change the LOGS directory
    log_directory = 'output_overshoot_fov0p3_f0ov0p005/LOGS'
    
and::

  ! change the png directory
    Grid1_file_dir = 'output_overshoot_fov0p3_f0ov0p005/png'
    
Similar as above, what do you expect your model to do when 
using higher core overshooting during core helium burning?
Should the convective core grow in mass, reach a similar 
value, or receed? 

Lets have a look, what MESA will tell us::

	./rn
	
Look again at the plot showing the growth of the convective
core mass. How does it compare to to the model with the 
weaker overshooting? Do you have an idea why?

* SOLUTION: The convective core reaches a very similar 
maximum mass as in the low overshooting case. Similar
as before, one can see that there are weak pulses in the 
mass growth that are linked to convection regions forming
directly on top of the overshooting region. It seems, like
these convective regions prevent the core to grow further.
This is a well-known problem that is encountered during
CHeB in low and intermediate mass stars. Here, the modelling
of the convective boundaries is challenging and have do
do with the Nabla_rad profile changing during the evolution
leading to the formation of with the formation of the
convective region forming when reaching a local minimum.
It is not clear if this of physical or numerical nature,
but you will learn more about this in the concluding lecture.

Numerical methods to prevent the formation of the convective zone
-----------------------------------------------------------------

Since it is not clear if the formation of this breathing 
pulses is physical or numerical, we would like to introduce 
an example of a numerical workaround to prevent the formation
of the convection zone on top of the overshooting zone. 

DO WE WANT TO SHOW THEM THAT? I THINK THE SOLUTION IS PREDICTIVE 
MIXING WITH EITHER ``predictive_avoid_reversal?`` or 
``predictive_superad_thresh``.


BONUS: Calculate a 15Msun star model until core helium burning
==============================================================

Model without overshooting
--------------------------

Model with weak overshooting
----------------------------

Model with strong overshooting
------------------------------
