
Introduction to running MESA
====================

..
  If you can't stand reading anything that isn't on the web, skip
  this and go directly to https://docs.mesastar.org.  Even if you do
  read this file, when you are done you should still go to that site!

These directions assume you have already installed MESA. Double check
if you have set your paths correctly by running::

    echo $MESA_DIR
    echo $MESASDK_ROOT

and checking if they indeed point to your MESA installation.

Copy this work directory to somewhere outside the mesa directory tree
and name it anything you like.

Compile by executing the ``clean`` and ``mk`` scripts::

    ./clean
    ./mk

This compiles the files in ``src/``, links them against MESA, and
produces the ``star`` executable file. In this first lab, you do not
need to worry about what is in that ``src/`` folder, we took care
of it ;)

By convention, run the program using the  ``rn`` script::

    ./rn

When MESA runs, it first reads the ``inlist`` file.  This file can
point to other inlist files.  Here, it points to ``inlist_project``
and ``inlist_pgstar``.

You can control MESA by editing the options in the various sections
of the inlist.  The full set of parameters and their default values
can be found in the defaults files listed in the inlists.

To restart MESA from a saved photo file, run the program using the
``re`` script::

    ./re [photo]

where ``[photo]`` is one of the saved snapshot files in ``photos``.
If no file is specified, MESA restarts from the most recent photo.


====================
Monday MaxiLab 1: Modelling core overshooting in main-sequence stars
====================

In this lab, you will learn how to set up a MESA model from scratch,
learn how to monitor the run, customise its output and how to choose
reasonable values for model parameters. Our science case is focused on
the effects of core overshooting on the core of main-sequence stars.

As a maxilab, this lab will take two 1.5h sessions. Each session is
organised in three sections, structured as below with an estimate of the
time you are expected to spend on each. Please do not hesitate to ask
your TA and/or the other people at your table for assistance if you
notice you are falling behind on schedule.

SESSION 1
  1. Setting up your MESA work directory [20']
  2. Modifying the input physics and saving your final model [30']
  3. Monitoring the run and customising output [40'] (move some stuff into session 2)

SESSION 2
  4. Adapting the input parameters [10'] (and play more with the pgstar plots?)
  5. Making your own plots [20']
  6. BONUS: automatically run multiple MESA models sequentially [20']

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


### Setting up your MESA work directory

1. We will start from the mostly empty default MESA work directory and
slowly build it up until we have a properly fleshed-out main-sequence
model. Make a new empty directory somewhere on your machine, go into
the empty directory and copy over the default MESA work directory:

    ``cp -r $MESA_DIR/star/work/ .``

Do a quick ``ls`` to check what is included in this default work directory.
You'll see a number of executables, namely _clean_, _mk_, _re_ and
_rn_. You can look at the summary at the start of this README to see what
these executables do. The subdirectories _make_ and _src_ contain the
Makefile and extra code to include, but you don't have to look into that
today. For now, let's take a look at the inlists _inlist_,
_inlist_pgstar_ and _inlist_project_. These files describe what you want
MESA to do. In particular MESA will always look for _inlist_. Using your
favourite text editor, take a look at what is in _inlist_.

What this _inlist_ essentially does is redirect MESA to the other two
inlist files for all the real content, with _inlist_project_ containing
most of the fields describing how the MESA run should go and
_inlist_pgstar_ describing what visuals MESA should produce. For now,
let's focus on _inlist_project_.


2. To start, let's run a very simple main-sequence model of a star with
an initial mass of 5 solar masses and metallicity of 0.014 with some
strong step-wise mixing due to core overshooting. To do so, open
_inlist_project_ and find and change the following parameters to the
given values:

- ``initial_m = 5d0``
- ``initial_z = 0.014d0``

Next, to add the core overshooting, we need to add in some new fields.
Before you try to do so, have a look at the questions below.

- ``overshoot_zone_type(1) = 'burn_H' ``
- ``overshoot_zone_loc(1) = 'core' ``
- ``overshoot_bdy_loc(1) = 'top' ``
- ``overshoot_scheme(1) = 'step' ``
- ``overshoot_f(1) = 0.30 ``
- ``overshoot_f0(1) = 0.005 ``

<span style="color:green">
**QUESTION**: The first three ``overshoot_`` fields describe where the
overshooting should take place. Go into
[the MESA documentation](https://docs.mesastar.org/en/latest/index.html)
and look up what each of these fields means. What other values are
available? Meanwhile, ``overshoot_scheme`` describes what shape the
overshoot mixing profile should take. Again, what are the alternatives
to our 'step'?
</span>
<br>
<br>

<span style="color:green">
**QUESTION**: ``overshoot_f`` and ``overshoot_f0`` describe how large the
overshooting region should be. How are they defined?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: Both are given in units of the local scale height.
``overshoot_f`` is the total size of the overshooting region,
while ``overshoot_f0`` describes how far into the convective region
the model should switch from mixing by convection to overshooting.
</span>
<br>
<br>


<span style="color:green">
**QUESTION**: Where should you add these fields?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: Strictly speaking, you can place them anywhere in the
``&controls`` namelist. However, you'll probably notice that ``&controls``
is organised into subsections like "starting specifications", "when to
stop", "wind" and so on. Generally speaking, sticking to this or a
similar structure is a good idea to keep your inlist clearly organised.
As such, we recommend adding these new fields under ``! mixing``.
</span>
<br>
<br>


<span style="color:green">
**BONUS QUESTION**: Why does each overshoot field in our example have
that ``(1)`` at the end?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: All these ``overshoot_`` are actually arrays and ``(1)``
indicates the first element of that array. This way, each element
can represent a different overshooting zone so you can use
different overshooting settings for each zone.
</span>
<br>
<br>


3. While looking around your _inlist_project_, you may have noticed the
field called ``ZBase`` under the ``&kap`` namelist. This describes
the reference metallicity used in the calculation of the opacities.
For consistency, you should set ``ZBase`` to the same value as
``initial_z``.


4. Before you run your model, you should consider when the model is
terminated. Since we want to simulate the main-sequence evolution,
we should place our stopping condition around the terminal age
main-sequence (TAMS). Look under ``! when to stop`` in ``&controls``
of your _inlist_project_.

You'll note there are two conditions that can trigger
the model to end. The first is designed to stop the model at the
zero-age main-sequence (ZAMS), which we obviously do not want.
Therefore, set

  ``stop_near_zams = .false. ``

The second condition is meant to stop the model around the TAMS.
Bear in mind that different people define
the TAMS in different ways, so you should always think about how
you want to define it.

<span style="color:green">
**QUESTION**: How does the default _inlist_project_ define the TAMS?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: [click here to reveal the answer] [TO DO] When the mass
fraction of $^1H$ drops below 0.001. For the sake of simplicity, we'll
stick to this easy definition today.
</span>
<br>
<br>


5.
Run your model by cleaning any executables in your work directory using

    ``./clean``

Then making a new executable using

    ``./mk``

and finally running that executable by

    ``./rn``

You'll notice that MESA writes a bunch of numbers describing your model to your
terminal, followed by regular updates on some key parameters summarising
the current state of your model. These are highly useful in examining how
your run is going. For instance, keep an eye on the central hydrogen
fraction (``H_cntr``) field, which will tell you how far along the main-
sequence evolution your model is. You'll note that it initially changes
extremely slowly. This is because MESA starts with a very small time step
which gradually increases, as shown by the ``lg_dt_yrs`` field.

After a while, two panels pop, one showing the evolutionary track of your
model on a Hertzsprung-Russell diagram and one the internal temperature
and density profiles. Like the terminal output, these help you keep an
eye on your model.


### Customising output

6. From all these numbers MESA wrote to your terminal, we've already
identified a way to improve the efficiency of our models.
The first 50 or so steps accomplish very little because the
time steps are very small. We can tell MESA to start with a time step
of one year, hence decreasing the required number of steps and speeding
up the run. To do so, add the following to the ``%star_job`` section of
_inlist_project_:

    ``set_initial_dt = .true.``
    ``years_for_initial_dt = 1d0``

Note that this will only take effect once the star has reached the ZAMS.

Moreover, you will have noticed that before the run truly stars, MESA
first creates a pre-main-sequence model and lets it relax for 300
steps. For our purposes today, this relaxation is not critical,
so let's reduce the number of relaxation steps to speed up the
initialisation of our model to 100. To do so, add the following to
your ``%star_job``:

    ``pre_ms_relax_num_steps = 100``


7. Now let's turn to these animated plots, often called
the pgstar plots. These are incredible useful in understanding what
is going on in your model while its running, helping you spot
potential problems early. Therefore, it is worthwhile to customise
your pgstar panels to show those quantities that are the most important
to your work. To this end, MESA has a bunch of prepared windows you can
easily add by adding one flag to your _inlist_pgstar_. You can find
these and how to edit your _inlist_pgstar_ in
[this documentation page]{https://docs.mesastar.org/en/24.08.1/reference/pgstar.html}.

For the purposes of this lab, we have prepared a specialised
_inlist_pgstar_ for you. Download that _inlist_pgstar_ here [TO DO]
and move it into your MESA work directory.

Run your model again to see what the new pgstar plots look like.
You don't have to wait for the run to be finished. You can interupt
it using ctrl+C if you're on Linux and Cmd+C if you're on Mac.

For some of you, this new panel may look terrible, either being very
small or overflowing out of your screen. This is because the width
of the pgstar window is dependent on your system and the size of
your screen. If the panel is too large or small for you, open
_inlist_pgstar_, find the two lines shown below near the start of
the inlist and play around with the values until it looks nice.

    ``Grid1_win_width = 10``
    ``Grid1_win_aspect_ratio = 0.7``

<span style="color: #1e118d ">
**HINT** : You can edit _inlist_pgstar_ while the model is running
and it will immediately update your plots.
</span>
<br>
<br>


8. We have merged all the plots in one panel for a better overview.
We also included some key quantities at the top, similar to MESA's
terminal output.
The plots are the HRD, a plot relating the star's age to the
model number and another MESA default panel: the mixing panel.
Finally, there is a mysterious mostly empty panel.
We'll get back to that empty panel later.


For now, focus on that mixing panel.

<span style="color:green">
**QUESTION**: What is the panel showing exactly? What does the colour
of each line indicate?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: MESA treats the mixing of chemicals as a diffusive process.
The y-axis shows the logarithm of the diffusive mixing coefficient in
cm^2/s (unless otherwise specified, MESA uses cgs units). The colour
indicates the process behind the mixing, blue for convection and white
for overshooting. These are the only two mixing processes in our model,
but there are a plethora of other processes MESA can include.
</span>
<br>
<br>


9. So far, so good! Now let's think about the age plot. This is an example
of a history panel, where we plot two history quantities, i.e.
quantities that vary over time. Since we will explore the effect of
overshooting on the core in the second half of this lab, it would be
more interesting to change the y-axis of the history panel to
something more relevant such as the core mass. However, to do so,
you first need some idea of what history quantities are available.

You may have noticed that since running your model, a new subdirectory
named _LOGS_ has appeared. That is the default directory to which MESA
writes its output. In there, you will find files named _history.data_
and _profile{i}.data_. These track how a number of quantities vary over
time and the star's radius respectively.

So far, your history and profile output only contain the default
columns. To see what history output is included, open _LOGS/history.data_
with a text editor. You'll note a header on the first few lines describing
some essential aspects of your run and then on line 6 the names of your
history columns. The meaning of some columns will be mostly clear from
the name, but some are a bit obtuse.

Both to find out what these columns mean and to include extra columns,
we need to examine the file listing which history columns our model
should output. First, copy the default history columns list to your
work directory. Let's also give it a new name:

    ``cp $MESA_DIR/star/defaults/history_columns.list my_history_columns.list``

Open _my_history_columns.list_ and take some time to scroll
through the wealth of possible output MESA offers. Can you find the
meaning of some of the columns you saw in your _history.data_ file?
You'll notice that some columns are not yet documented. Feel very
free to ask the MESA developers present what they mean.

In this lab, we are interested in the effects of overshooting on the
stellar core. The mass of the convective core is already included in
the defaults. Now add the stellar radius and radius of the convective
core to the history output. Look for and uncomment the appropriate
fields.

<span style="color: #1e118d ">
**HINT** : The radius of the star is simply called 'radius'.
</span>
<br>
<br>

<span style="color: #1e118d ">
**HINT** : For the radius of the convective core, look under the section
marked by ``!## mixing regions``. Which field here would provide the
core radius in a main-sequence star with a fairly large convective core?
How would you make sure the definition of this radius is consistent with
the core mass?
</span>
<br>
<br>

<span style="color: #1e118d ">
**HINT** : For the radius, take the field ``conv_mx1_top_r``. To guarantee
consistency with the core mass, use ``conv_mx1_top`` for your core mass.
Be aware that these are relative to the total radius and mass!
</span>
<br>
<br>

Once you have uncommented the relevant lines, you need to tell your MESA
inlist that you want to include the output columns in
_my_history_columns.list_ under ``&star_job`` :

    ``history_columns_file = 'my_history_columns.list'``


10. Now we can finally turn back to the pgstar history plot. Open up
_inlist_pgstar_ and navigate to the section where the history panel
is defined. Change the left y-axis to the default quantity of the
convective core mass.  

    ``History_Panels1_yaxis_name(1) = 'mass_conv_core'``

<span style="color: orange ">
**BONUS**: You could also use this panel to directly compare the
two different definitions we might use. How would you go about that?
</span>
<br>
<br>

<span style="color: #1e118d ">
**HINT**: [click here to reveal the answer] [TO DO] The optional
field ``History_Panels1_other_yaxis_name(1)`` lets you set the
right y-axis.
</span>
<br>
<br>

<span style="color: orange ">
**BONUS QUESTION**: Which of these two definitions seems more
convenient to you? And what about the definition of the core radius?
</span>
<br>
<br>

What history and profile quantities we ask MESA to include not only changes
the output of our model, but also impacts pgstar's plotting options.
For instance, in order to plot a full Kippenhahn diagram, MESA needs to
keep close track of all the mixing regions. In order to enable that, go
into _my_history_columns.list_ and find the option named ``mixing_regions``.
As you can read in its description in _my_history_columns.list_, this is
not one quantity, but automatically adds a number of history columns.
Try uncommenting this ``mixing_regions`` and give it a fairly large integer
to ensure it includes all the relevant mixing zones, e.g.

    ``mixing_regions 20``

Your pgstar window should now include fully functional panels. Briefly
run your model again to double check everything works as it should.


11. The history files tell you how chosen quantities vary over time. But
what about quantities that vary over the star's radius? Those are
described by the files _profile{i}.data_ in the LOGS folder. As with
the history, let's check study what is included by default and add
a few columns. First copy over the list file:

    ``cp $MESA_DIR/star/defaults/profile_columns.list my_profile_columns.list``

Again, take a few minutes to check out what it has to offer. Later
in this lab, we will examine the mixing profile at different times.
To this end, you will need the profile of the (logarithmic) diffusive
mixing coefficient and some way to tell what process is causing that
mixing. Find and uncomment some appropriate fields.

<span style="color: #1e118d ">
**HINT**: At minimum, include the fields ``log_D_mix`` and
``mixing_type``. Adding the contributions of each mixing type
separately using ``log_D_conv``, ``log_D_ovr`` & co. is also
recommended.
</span>
<br>
<br>

Remember to add your profile column list to your inlist!

    ``profile_columns_file = 'my_profile_columns.list'``


<span style="color: orange ">
**BONUS QUESTION**: How often does MESA produce a profile file? How could
you increase this resolution?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: [click here to reveal the answer] [TO DO] By default, MESA
produces a profile every 50 model steps. The most straightforward way
to increase the frequency of the output is using ``profile_interval``
in your inlist's ``&controls`` section. You could also set
``write_profile_when_terminate = .true.``.
</span>
<br>
<br>


12. In the other labs today, you will learn how to run models that continue
after the main-sequence evolution. When doing so, it is quite annoying to
have to simulate the main-sequence again every time you tweak something in
your inlist. Instead, we can tell MESA to save a model at the end of a
main-sequence run so we can load that model in next lab. Add this to your
``%star_job`` and name your model:

    save_model_when_terminate = .true.
    save_photo_when_terminate = .true.
    ! Give a name to the model file to be saved including your parameter values, e.g.
    ! 'M{your_M}_Z{your_Z}_fov{your_f_overshoot}_f0ov{your_f0_overshoot}.mod'
    save_model_filename = ! Add your name here


13. Now let's run the model all the way to the end.
As the model runs, keep an eye on your new mixing panel in particular.
Compare it to those of the other people at your table.


### Studying the output

2. Go into
[this spreadsheet](https://docs.google.com/spreadsheets/d/1qSNR-dV28Tr_RWv3bDu8OYsq7jTVcTQxmqzWqLM52es/edit?usp=sharing)
and put your name next to one set of parameters to claim it as yours.


If you selected the **'no overshoot'** scheme from the spreadsheet,
you should comment all the lines starting with ``overshoot_`` by
adding an exclamation mark (``!``) in front.

11. Using your favourite text editor, open the history.data file and find
the line describing the TAMS. Add the values of the following parameters
to the second page of the spreadsheet. Take care to check your units!

 - log(Teff)
 - log(L)
 - core mass
 - core radius
 - age in Myr

MATHIJS TO TEAM: What output would be most useful? Teff and L are no-brainers
and the core conditions are relevant as well. What else?

12. Now let's wrap up this lab by reading your MESA output in using Python
and making some custom plots.

MATHIJS TO TEAM: What kind of plots should we have them make? One idea is
to make them plot the mixing profile of every profile together in one plot.
Another obvious option is to plot core mass/radius against (a proxy of) time.
