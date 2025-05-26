
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



Monday Lab 1: Modelling overshooting in massive main-sequence star
====================

In this lab, we will examine how overshooting of a convective core
affects a star's evolution together. In particular, we will examine
how the numerical simplifications in this modelling may affect model.
In doing so, we will learn how to find reasonable values for
model parameters, namely the initial mass of the star $M_\rm{ini}$,
its initial metal mass fraction $Z$, the overshoot parameter $f_\rm{ov}$
which describes how far from the core the overshoot can reach and $f_0$
which describes how deep in the convection zones the model switches
from mixing by convection to overshoot. To this end, everyone picks one
set of parameter values to simulate, after which we will collect
everyone's results and look for trends. If you have time left over,
you may pick and run a second set of parameters.


### Your first main-sequence model

1. Download the MESA work directory here. [TO DO]


2. Go into
[this spreadsheet](https://docs.google.com/spreadsheets/d/1qSNR-dV28Tr_RWv3bDu8OYsq7jTVcTQxmqzWqLM52es/edit?usp=sharing)
and put your name next to one set of parameters to claim it as yours.


3. Open the file _inlist_project_, which describes the physical and
numerical settings of the run, and set the following parameters
in the ``&controls`` section according to the set of values you claimed.
Check [the MESA documentation](https://docs.mesastar.org/en/latest/index.html)
to ensure you are using the correct units for ``initial_m``.

- ``initial_m``
- ``initial_z``
- ``overshoot_scheme``
- ``overshoot_f(1)``
- ``overshoot_f0(1)``

If you selected the **'no overshoot'** scheme from the spreadsheet,
you should comment all the lines starting with ``overshoot_`` by
adding an exclamation mark (``!``) in front.

For consistency, you should also go to the ``&kap`` section and set
``ZBase`` to the same value as ``initial_z`` such that the opacities
used in the model are consistent with this metallicity. Moreover, you
should normally think about how to change the initial hydrogen and
helium fraction based on the metal fraction, but to keep things simple,
we have already done this for you so you can ignore that for now.

You are now ready to try and run your model from the star's birth to the
terminal age main-sequence (TAMS). Bear in mind that different people define
the TAMS in very different ways.

<span style="color:green">
**QUESTION**: How did we define the terminal age main-sequence in
_inlist_project_?
</span>
<br>
<br>

<span style="color: #148f77 ">
**ANSWER**: [click here to reveal the answer] [TO DO] When the mass fraction of
$^1H$ drops below 0.001
</span>
<br>
<br>

4.
Run your model by cleaning any executables in your work directory using

    ./clean

Then making a new executable using

    ./mk

and finally running that executable by

    ./rn

You'll notice that MESA is writing some text describing your model to your
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


### Customising resolution and output

5.
After this first basic run, we can identify some ways to improve our
model. Firstly, the first 100 or so steps accomplish very little as the
time steps are very small. We can tell MESA to start with a larger time
step, hence decreasing the required number of steps and speeding up the
run. To do so, add the following to the ``%star_job`` section of
_inlist_project_:

    set_initial_dt = .true.
    years_for_initial_dt = 1d3

Note that this will only take effect once the star has reached the zero
age main-sequence.

We can use the time saved to improve the spatial and temporal resolution
of the model. The simplest way to do so is using ``mesh_delta_coeff``
and ``time_delta_coeff``. Add this to your ``%controls``:

    time_delta_coeff = 0.8d0
    mesh_delta_coeff = 0.5d0

This will improve the overall spatial resolution by a factor of roughly
2 and the temporal resolution by roughly 25%.


6. As we want to examine the impact of mixing by overshooting, it would be
nice to have a visual of the mixing profile. Luckily, it is easy to add a
PGPLOT window showing exactly that!

Open the file _inlist_pgstar_ and add and complete the following.

    Mixing_win_flag = .true.
    Mixing_win_width = ! Add your value here
    Mixing_win_aspect_ratio = ! Add your value here

The ideal width and aspect ratio to assign depends on your machine as well
as your personal preferences, so you should play around with these
values if you have some extra time. For now, you should look up the
default values in the documentation and start from those.

<span style="color: orange ">
**BONUS**:
It is often more convenient to have all the plots together in one big panel.
To do so, etc.

MATHIJS TO TEAM: Do you think this is a reasonable way to get interested
students to poke around in pgstar? If so, does anyone already have an
example inlist on hand?

</span>
<br>
<br>

7.
So far, your history and profile output only contain some basic default
columns. To see what history output, i.e. how selected quantities vary
over time, go into the LOGS/ folder in your work directory and open
_history.data_. You'll note a header on the first few lines describing
some essential aspects of your run and then on line 6 the names of your
history columns. The meaning of some columns will be mostly clear from
the name, but some are a bit obtuse.

Both to find out what these columns mean and to include extra columns,
we need to examine the file listing which history columns our model
should output. First, copy the default history columns list to your
work directory. Let's also give it a new name:

    cp $MESA_DIR/star/defaults/history_columns.list my_history_columns.list

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

    history_columns_file = 'my_history_columns.list'



8.
The history files tell you how chosen quantities vary over time. But
what about quantities that vary over the star's radius? Those are
described by the files _profile{i}.data_ in the LOGS folder. As with
the history, let's check study what is included by default and add
a few columns. First copy over the list file:

    cp $MESA_DIR/star/defaults/profile_columns.list my_profile_columns.list

Again, take a minute or two to check out what it has on offer. Later
in this lab, we will examine the mixing profile at different times.
To this end, you will need the profile of the (logarithmic) diffusive
mixing coefficient and some way to tell what process is causing that
mixing. Find and uncomment some appropriate fields.


<span style="color: #1e118d ">
**HINT**: At minimum, include the fields ``log_D_mix`` and
``mixing_type``. Adding the contributions of each mixing type
seperately using ``log_D_conv``, ``log_D_ovr`` & co. is also
recommended.
</span>
<br>
<br>

Remember to add your profile column list to your inlist!

    profile_columns_file = 'my_profile_columns.list'



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


9.
In the other labs today, you will learn how to run models that continue
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


10. Now let's run the model again using ``./rn``.
As we did not change any of the code, just the inlist's input, you do not have
to run ``./clean`` or ``./mk`` again, though you can do so if you'd like.

As the model runs, keep an eye on your new mixing panel in particular.
Compare it to those of the other people at your table.


### Studying the output

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
