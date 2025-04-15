This is a very basic model to show how overshooting during late
evolutionary stages can mess with the cores convective boundaries.

I assume no mass-loss. If we want to go to higher masses, we might
want to include that. 

I use a uniform composition and the standard MLT option from MESA.
We might want to check if this issues persits when using e.g. COX

I added inlist_extra where the students can make their changes. 
The parameters in inlist_project should be fixed for all test runs

Another option to test is prune_bad_cz_min_Hp_height or 
prune_bad_cz_min_log_eps_nuc as suggested by Sunny
