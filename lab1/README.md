# Introduction to running MESA

[PDF](pdf/README.pdf)

# Monday MaxiLab 1: Modelling core overshooting in main-sequence stars

In this lab, you will learn how to set up a MESA model from scratch,
learn how to monitor the run, customise its output and how to choose
reasonable values for model parameters. Our science case is focused on
the effects of core overshooting on the core of main-sequence stars.

As a maxilab, this lab will take two 1.5h sessions. Each session is
organised in three sections, structured as below with an estimate of the
time you are expected to spend on each. Please do not hesitate to ask
your TA and/or the other people at your table for assistance if you
notice you are falling behind on schedule.

---

### **Session 1**

**1. Setting up your MESA work directory**
- *\~20 minutes*
- Learn how to initialize a new MESA run directory from the default templates and understand the directory structure.

**2. Modifying the input physics and saving your final model**
- *\~30 minutes*
- Adjust the inlist files to define key input physics, like overshooting and metallicity. Save the resulting model.

**3. Monitoring the run and customizing output**
- *\~40 minutes*
- Use `pgstar` and log file outputs to visualize evolution.


### **Session 2**

**4. Adapting the input parameters**
- *\~10 minutes*
- Make further changes to the inlist (e.g. adjust mass, overshoot params, timestep) and observe effects.

> *(You can also tweak your `pgstar` plots more here)*

**5. Making your own plots**
- *\~20 minutes*
- Extract and visualize data from `history.data` and `profile.data` using Python, matplotlib, or pgstar.

**6. BONUS: Automatically run multiple MESA models sequentially**
- *\~20+ minutes*
- Learn to loop over parameter grids using shell scripts or Python (e.g., `inlist_template` + script).

---

In this lab, we will examine how overshooting of a convective core
affects a star's evolution together. In particular, we will examine
how the numerical simplifications in this modelling may affect the model.
In doing so, we will learn how to find reasonable values for
model parameters, namely the initial mass of the star $M_\rm{ini}$,
its initial metal mass fraction $Z$, the overshooting scheme, overshoot
parameter $f_\rm{ov}$ which describes how far from the core the overshoot
can reach and $f_0$ which describes how deep in the convection zones the
model switches from mixing by convection to overshoot. To this end,
everyone picks one set of parameter values to simulate, after which we
will collect everyone's results and look for trends together. You will
also learn how to navigate the MESA output in greater detail and make
fully custom plots in Python, both using the dedicated ``mesa_reader``
Python package as well as 'by hand'.
If you have time left over, you can look into some prepared scripts that
automatically write parameter values into your inlist and runs different
sets of parameters sequentially.

---

## SESSION 1

### Setting up your MESA work directory

1. We will start from the mostly empty default MESA work directory and
slowly build it up until we have a properly fleshed-out main-sequence
model. Make a new empty directory called lab1, go into
the empty directory and copy over the default MESA work directory:

```bash
    mkdir lab1
    cd lab1
    cp $MESA_DIR/star/work/* .
```

Do a quick ``ls`` to check what is included in this default work directory.
You'll see a number of executables, namely _clean_, _mk_, _re_ and
_rn_. You can look at the summary at the start of this README to see what
these executables do. The subdirectories _make_ and _src_ contain the
Makefile and extra code to include, but you don't have to look into that
today. For now, let's take a look at the inlists _inlist_,
*inlist_pgstar* and *inlist_project*. These files describe what you want
MESA to do. In particular MESA will always look for _inlist_. Using your
favourite text editor, take a look at what is in _inlist_.

What this _inlist_ essentially does is redirect MESA to the other two
inlist files for all the real content, with *inlist_project* containing
most of the fields describing how the MESA run should go and
*inlist_pgstar* describing what visuals MESA should produce. For now,
let's focus on *inlist_project*.


2. To start, let's run a very simple main-sequence model of a star with
an initial mass of 5 solar masses and metallicity of 0.014 with some
strong step-wise mixing due to core overshooting. To do so, open
*inlist_project* and find and change the following parameters to the
given values:


```fortran
initial_m = 5d0
initial_z = 0.014d0
```

The opacity table MESA uses depends on the reference metallicity,
defined by ``ZBase`` under the ``&kap`` namelist.
For consistency, you should set ``ZBase`` to the same value as
``initial_z``:

```fortran
ZBase = 0.014d0
```

3. Next, to add the core overshooting, we need to add in some new fields.
Before you try to do so, have a look at the questions below.

```fortran
overshoot_zone_type(1) = 'burn_H'
overshoot_zone_loc(1) = 'core'
overshoot_bdy_loc(1) = 'top'
overshoot_scheme(1) = 'step'
overshoot_f(1) = 0.30d0
overshoot_f0(1) = 0.005d0
```

**Question**: The first three `overshoot_` fields describe where the  
overshooting should take place. Go into  
[the MESA documentation](https://docs.mesastar.org/en/latest/reference/controls.html)
and look up what each of these fields means.  


<details>
<summary>Show answer</summary>

`overshoot_zone_type` lets you indicate to only activate overshooting around
regions where certain types of burning takes place. `overshoot_zone_loc` then
tells MESA whether this convection zone should reach down to the core or not
and `overshoot_bdy_loc` whether the overshoot should occur only above or under
 the relevant convection zone(s).

</details>


**Question**: Where should you add these fields?


<details>
<summary>Show answer</summary>

Strictly speaking, you can place them anywhere in the `&controls` namelist.  
However, you'll probably notice that `&controls` is organised into subsections like  
"starting specifications", "when to stop", "wind" and so on.  
Generally speaking, sticking to this or a similar structure is a good idea  
to keep your inlist clearly organised.  
As such, we recommend copy-pasting the six lines above under "mixing".

</details>


**Bonus Question**: Why does each overshoot field in our example have that `(1)` at the end?


<details>
<summary>Show answer</summary>

All these `overshoot_` are actually arrays and `(1)`  
indicates the first element of that array.  
This way, each element can represent a different overshooting zone  
so you can use different overshooting settings for each zone.

</details>



4. Before you run your model, you should consider when the model is
terminated. Since we want to simulate the main-sequence evolution,
we should place our stopping condition around the terminal age
main-sequence (TAMS). Look under ``! when to stop`` in ``&controls``
of your *inlist_project*.

You'll note there are two conditions that can trigger
the model to end. The first is
```fortran
Lnuc_div_L_zams_limit = 0.99d0
stop_near_zams = .true.
```  
which is designed to stop the model at the zero-age main-sequence (ZAMS),
that it defines as the point where 99% of the energy released comes from
nuclear reactions. As we seek to model the main-sequence, we obviously
do not want the run to end around the ZAMS. Therefore, set

```fortran
stop_near_zams = .false.
```  

The second condition is meant to stop the model around the TAMS.
```fortran
xa_central_lower_limit_species(1) = 'h1'
xa_central_lower_limit(1) = 1d-3
```

**Question**: How does the default *inlist\_project* define the TAMS?


<details>
<summary>Show answer</summary>

When the mass fraction of \$^1\$H drops below 0.001.

</details>

For our purposes today, it will be interesting to go a little bit
further. Therefore, change the lower limit on \$^1\$H to 10^-6:

```fortran
xa_central_lower_limit_species(1) = 'h1'
xa_central_lower_limit(1) = 1d-6
```


5. Run your model by cleaning any executables in your work directory using

```bash
./clean
./mk
./rn
```

As your model runs, you will notice that MESA writes heaps of numbers
to your terminal. After a while, two panels with constantly
changing plots pop up. They show the evolutionary track of your
model on a Hertzsprung-Russell diagram and one the internal temperature
and density profiles. These help you keep a close eye on your model
and can help you identify problems and potential improvements.

For now, let's focus on the terminal output. One important field for our
purposes are the central hydrogen fraction (``H_cntr``), which will tell
you how far along the main-sequence evolution your model is. You'll note
that it initially changes extremely slowly. This is because MESA starts
with a very small time step which gradually increases, as shown by the
``lg_dt_yrs`` field, the base 10 logarithm of the time step expressed in
years.



6. Before running our main model, let's make two adjustments to speed up the MESA run:

MESA starts by creating a pre-main-sequence model (before nuclear burning begins) and by default performs 300 relaxation steps to ensure it's stable. For our educational purposes, we can reduce this to save time:

```fortran
pre_ms_relax_num_steps = 100
```

MESA also starts with very tiny time steps after reaching the main sequence. We can tell it to use larger initial steps:

```fortran
set_initial_dt = .true.
years_for_initial_dt = 1d0
```

Add both settings to the `&star_job` section of your *inlist_project*.

These adjustments will help our model run faster, especially during the early phases. In your future research, you'd want to carefully test how these parameters affect your specific science case, but for this lab, these settings are fine.

If you want to (and are on schedule), you can briefly run your model
again by entering `./rn` in your terminal to test whether
your changes to the inlist did what they are supposed to. You don't
have to run your model all the way to the TAMS. You can interupt
it using ctrl+C if you're on Linux and Cmd+C if you're on Mac.

<details> <summary>Show hint</summary>
In step 7, you reduced the number of pre-main-sequence relaxation steps from 300 to 100.
You also set the initial timestep to 1 year, which should be reflected in the lg_dt_years
value of the first few steps. The He_cntr of the first steps should also show your new value
for initial_y. You could also compare the values of some metals with your first run if you
haven't removed that terminal output yet. Finally, you should see the total mass of your model
decreasing slightly.
</details>


### Upgrading the physics

7. *inlist_project* is currently mostly empty. This means that most
settings are using MESA's default values. You should always check
whether these are appropriate for your models. As an example, since
this lab concerns fairly massive stars, mass loss by winds may play
a considerable role.


Check the documentation of `&controls` to see what the default mass
loss is.

<details>
<summary>Show hint</summary>

In the panel on the left, navigate to
**Reference and Defaults > controls**.
On the right, you can now see the contents of this page. Mass loss
by winds is found under **mass gain and loss**.

</details>


<details>
<summary>Show answer</summary>

Broadly speaking, you can add mass loss by either setting a constant, negative value to the field `mass_change`
(with or without rotational scaling) or with some `wind_scheme`.

</details>

You will see in the documentation that there is a wealth of wind mass loss schemes available,
all of which can be scaled up or down. Each scheme is appropriate in particular regimes of the surface temperature, composition, etc.
The so-called Dutch scheme attempts to merge some of these schemes into a cohesive whole.
Add it into your *inlist\_project* without scaling.


<details>
<summary>Show hint</summary>

In order to use the Dutch scheme at all temperature ranges and without changing its scaling, use:

```fortran
hot_wind_scheme = 'Dutch'
cool_wind_RGB_scheme = 'Dutch'
Dutch_scaling_factor = 1d0
```

</details>


8. MESA uses the mixing-length theory (MLT) to describe the
transport by convection. This theory relies on a scaling factor
$\alpha_{MLT}$ which is in general quite poorly calibrated.
As such, you should check what MESA's default value of this
$\alpha_{MLT}$ parameter is.

<details>
<summary>Show hint</summary>

The field setting $\alpha_{MLT}$ is called `mixing_length_alpha`.
You can easily navigate to its description by entering this field
name into the search bar on the top left of the MESA documentation
website. If you do so, it's best to click on *controls > mixing_length_alpha*
since that will take you straight to the description of mixing_length_alpha.
</details>


When you are working on your real science cases, you should
test a few different values for this $\alpha_{MLT}$ to gain
an understanding of its effects. However, to save some time
in this lab, we will stick to just one value, namely 1.8.
Add this into your *inlist_project*

```fortran
mixing_length_alpha = 1.8d0
```


9. In the other labs today, you will learn how to run models that continue
after the main-sequence evolution. When doing so, it is quite annoying to
have to simulate the main-sequence again every time you tweak something in
your inlist. Instead, we can tell MESA to save a model at the end of a
main-sequence run so we can load that model in next lab. Add this to your
``%star_job`` and name your model:

```fortran
save_model_when_terminate = .true.
save_photo_when_terminate = .true.
! Give a name to the model file to be saved including your parameter values, e.g.
! 'M{your_M}_Z{your_Z}_fov{your_f_overshoot}_f0ov{your_f0_overshoot}.mod'
save_model_filename = 'M5_Z0014_fov030_f0ov0005_TAMS.mod'
```

10. Despite how much you already added into your *inlist_project*,
there are still many empty headers. Indeed, when building
an inlist for your real science cases, you should still look
into your opacity tables, atmosphere settings, equation of state,
spatial and temporal resolution, and much more besides.
However, for the sake of time and not making this lab too
repetitive, we'll stop here.

Now let's run the model again! To do so, enter
```bash
./rn
```
into your terminal. When the run is finished, double check if
the new file 'M5_Z0014_fov030_f0ov0005_TAMS.mod' is in your work
directory.


### Customising output

10. Now let's turn to these animated plots, often called
the pgstar plots. These are incredible useful in understanding what
is going on in your model while its running, helping you spot
potential problems early. Therefore, it is worthwhile to customise
your pgstar panels to show those quantities that are the most important
to your work. To this end, MESA has a bunch of prepared windows you can
easily add by adding one flag to your *inlist_pgstar*. You can find
these and how to edit your *inlist_pgstar* in
[this documentation page](https://docs.mesastar.org/en/24.08.1/reference/pgstar.html).

For the purposes of this lab, we have prepared a specialised
*inlist_pgstar* for you. Download that *inlist_pgstar* here [TO DO]
and move it into your MESA work directory.

Run your model again to see what the new pgstar plots look like.
You don't have to wait for the run to be finished. Remember that
you can interrupt it using ctrl+C if you're on Linux and Cmd+C if
you're on Mac.

For some of you, this new panel may look terrible, either being very
small or overflowing out of your screen. This is because the width
of the pgstar window is dependent on your system and the size of
your screen. If the panel is too large or small for you, open
*inlist_pgstar*, find the two lines shown below near the start of
the inlist and play around with the values until it looks nice.

```fortran
Grid1_win_width = 10
Grid1_win_aspect_ratio = 0.7
```

<details> <summary>Show hint</summary>
You can edit *inlist_pgstar* while the model is running
and it will immediately update your plots.
</details>


11. We have merged all the plots in one panel for a better overview.
We also included some key quantities at the top, similar to MESA's
terminal output.


The plots are:
- Top left: The Hertzsprung-Russell diagram (HRD),
- Top right: History panel showing model number on the x-axis and age on the y-axis.  
  (This is often used as a proxy for age since model number increments regularly during evolution),
- Bottom right: The mixing panel,
- Bottom left: This is a mysterious mostly empty panel. We'll get back to that empty panel later.

### We'll refer to the “history plot” (top right) throughout the lab, so keep that panel in mind.



For now, focus on that mixing panel in the top right.


**Question**: What is the mixing panel showing exactly? What does the colour of each line indicate?


<details>
<summary>Show answer</summary>

MESA treats the mixing of chemicals as a diffusive process.
The y-axis shows the logarithm of the diffusive mixing coefficient in cm²/s
(unless otherwise specified, MESA uses cgs units).
The colour indicates the process behind the mixing — blue for convection and white for overshooting.
These are the only two mixing processes in our model, but there are a plethora of other processes MESA can include.

</details>


12. Customizing MESA's Output Data

In your pgstar window, look at the plot in the **top right corner**. 
This panel is showing how model properties change over time, currently using model number as the x-axis (In many cases, the absolute age of the star doesn’t matter. Since age correlates closely with model number, and model number is easier to interpret, we often use it as a proxy).
Since we're studying core overshooting effects, we'd like to modify this panel to show the evolution of the core mass instead of the default value.

To customize what's displayed in MESA plots, we first need to understand what data is being tracked. When MESA runs, it creates a `LOGS` directory containing two main types of output files:

- `history.data`: Records global stellar properties at each timestep
- `profile*.data`: Captures the star's internal structure at specific timesteps


Open `LOGS/history.data` with a text editor. After the header information, you'll see a list of column names around line 6. 
These are all the quantities MESA has been tracking during your run.

To add more quantities to track, we need to customize the history columns list:

```bash
cp $MESA_DIR/star/defaults/history_columns.list my_history_columns.list
```

Open `my_history_columns.list` and explore the wealth of available output options.
The file is organized by category, with comments explaining each variable.
This gives you a comprehensive view of what MESA can track.

For our overshooting study, we're interested in the stellar core properties. 
The convective core mass is already included in the defaults. 
Let's add the star's radius to the history output by finding and uncommenting the `radius` field in the appropriate section.


<details>
<summary>Show hint</summary>

The radius of the star is simply called `radius`.

</details>

Once you have uncommented the relevant lines, you need to tell MESA  that you want to include the output columns in _my_history_columns.list_. To do so, add the following line into your *inlist_project* under ``&star_job`` :

```fortran
history_columns_file = 'my_history_columns.list'
```



13. Configuring the History Plot

Now let's customize the History Panel in the pgstar window. This panel shows how stellar properties evolve over time.

1. Open `inlist_pgstar` in your text editor
2. Find the section that defines the History Panel (search for "History_Panels1")
3. Change the y-axis to display the convective core mass:

```fortran
History_Panels1_yaxis_name(1) = 'mass_conv_core'
```

This will show how the convective core mass evolves throughout the star's main sequence lifetime.

To enable more advanced plotting features like the Kippenhahn diagram (which shows the internal structure evolution), we need to tell MESA to track additional data:

1. Open `my_history_columns.list`
2. Find and uncomment the following options:

```fortran
mixing_regions 20
burning_regions 20
```

These settings tell MESA to track up to 20 distinct mixing and nuclear burning regions within the star, which enables the creation of Kippenhahn diagrams and other detailed evolutionary plots.

Run your model briefly to confirm your pgstar window now displays the updated plot configuration.

14. Profile Data (optional)

While history files track global properties over time, profile files capture the star's internal structure at specific moments. These are essential for examining how variables change with radius inside the star.

```bash
cp $MESA_DIR/star/defaults/profile_columns.list my_profile_columns.list
```

To study mixing processes in the stellar interior, uncomment these fields:
- `log_D_mix` - the diffusion coefficient for mixing
- `mixing_type` - identifies which mixing process is active in each zone

After modifying this file, tell MESA to use your custom profile columns by adding to your `inlist_project` under `&star_job`:

```fortran
profile_columns_file = 'my_profile_columns.list'
```

---

**Bonus Question**: By default, MESA only saves a profile every 50 model steps. This might miss important evolutionary phases. How could you increase this frequency?

<details>
<summary>Show answer</summary>
Add <code>profile_interval = 10</code> to your inlist's <code>&controls</code> section to save profiles more frequently. You could also enable <code>write_profile_when_terminate = .true.</code> to guarantee a profile at the end of the run.
</details>
---

## SESSION 2

### Trying different the overshoot settings

You now know how to navigate your work directory and build up a
main-sequence model. That's great. However, so far we have
limited ourselves to simply adding in pre-chosen parameter values,
choices of tables etc. In real scientific applications, you should
always consider the impact of these settings, for instance by
trying a few different values. In particular, there are a number
numerical schemes and poorly calibrated physical parameters for
which you should think carefully about the appropriate value.
You already encountered some of these today, namely the
mixing length parameter $\alpha_{MLT}$ and the mixing by
overshooting.

In this session, we'll explore the impact of overshooting in
your model. Through your experiments and the lecturer's
discussion of everyone's result, you will learn how you
can find reasonable values and settings for overshooting
in your model. The plan is that everyone gets a unique
set of overshooting parameters, initial mass and initial
metallicity to try out. You will then compare the results
of these parameter settings to the model you produced in
lab 1. Meanwhile, we will collect some basic results from
everyone's model and examine the correlations between
different parameters together.

17. Go into
[this spreadsheet](https://docs.google.com/spreadsheets/d/1qSNR-dV28Tr_RWv3bDu8OYsq7jTVcTQxmqzWqLM52es/edit?usp=sharing)
and put your name next to one set of parameters to claim it as yours.
Modify your inlist accordingly.

Given that there are more parmeter sets than students here so you are able to test different parameters if time is permitting, though focus should be on completing this task and fully understanding it. Also, the bonus tasks in this lab are concerning running this set of parameters in a batch. 

If you selected the **'no overshoot'** scheme from the spreadsheet,
you should leave the overshoot scheme as an empty string, i.e.

```fortran
overshoot_scheme(1) = ''
```

> **Reminder**: Use the same naming format for your save files and logs as below:
>
> `save_model_filename = 'M{mass}_Z{Z}_{scheme}_fov{fov}_f0{f0}.mod'`  
> `log_directory = 'LOGS_M{mass}_Z{Z}_{scheme}_fov{fov}_f0{f0}'`



18. Preserving Your Previous Results

Before running a new model with different parameters, we need to ensure we don't overwrite our previous results. We'll make two adjustments to keep our work organized:


After selecting your parameter set from the spreadsheet, modify the `save_model_filename` in your `inlist_project` file to reflect these specific parameters:

```fortran
save_model_filename = 'M{mass}_Z{metallicity}_{scheme}_fov{fov}_f0{f0}.mod'
```

For example, if you selected a 15 $M_\odot$ star with $Z=0.014$, exponential overshooting with $f_\text{ov}=0.01$ and $f_0=0.001$, your filename would be:

```fortran
save_model_filename = 'M15_Z0.014_exponential_fov0.01_f00.001.mod'
```

MESA normally writes all history and profile data to a directory called `LOGS/`. To keep these outputs separate from your previous run, we'll direct MESA to use a different output directory.

Add the following to your `inlist_project` under the `&controls` section:

```fortran
log_directory = 'LOGS_M{mass}_Z{metallicity}_{scheme}_fov{fov}_f0{f0}'
```

Using the same example parameters as above:

```fortran
log_directory = 'LOGS_M15_Z0.014_exponential_fov0.01_f00.001'
```

This keeps all your runs organized with descriptive names that make it easy to identify which parameters were used for each model.

19. Now run your model again. Keep a close eye on your pgstar plots,
particularly the mixing panel. Compare it with those of the
other people at your table.

20. After your model finishes running, we'll extract key parameters at the Terminal Age Main Sequence (TAMS).

Open the final history.data file in your new LOGS directory with a text editor. The TAMS is represented by the final line in this file - this is where the central hydrogen has been depleted to the threshold we set (1d-6).

From this final line, record the following values in the second page of the spreadsheet:
- log_Teff (logarithm of effective temperature)
- log_L (logarithm of luminosity in solar units)
- mass_conv_core or he_core_mass (depending on which is available)
- conv_mx1_top_r (if you uncommented this)
- star_age/1e6 (to convert to Myr)

These values will allow us to analyze how different overshooting parameters affect stellar evolution.

21. Now let's wrap up this lab by reading your MESA output in using Python
and making some custom plots.

---

## BONUS: Batch Parameter Studies with MESA

If you've completed the main lab activities and have time remaining, explore the automated parameter study framework in the [`batch_runs/`](./batch_runs) directory. This framework enables systematic exploration of overshooting effects across multiple stellar models.

### Why Run Batch Studies?

1. **Efficiency**: Run dozens of MESA models without manual intervention
2. **Thoroughness**: Test how overshooting parameters affect stellar evolution across different masses and metallicities
3. **Reproducibility**: Generate standardized output for consistent analysis


### Available Parameter Space

The provided parameter grid explores:
- Stellar masses: 2, 5, 15, 30 M☉
- Metallicities: Z = 0.014, 0.0014
- Overshooting schemes: None, Exponential, Step
- Overshooting parameters: 0.01-0.3
- Penetration depths: 0.001-0.01

For complete documentation and additional analysis tools, see [`bonus_tasks/README.md`](./bonus_tasks/README.md).
