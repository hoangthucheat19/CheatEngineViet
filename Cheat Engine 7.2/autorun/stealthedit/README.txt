How to setup:
In cheat engine 6.1+svn go to settings->plugins and click add.
Then find stealthedit.dll and add it to the plugin list.
Check the checkbox left of it to enable it and click ok to exit the settings screen

And make sure you've configured your bios to ALLOW the no-execute ability

How to use:
-On the run-
Rightclick the page you want to stealthedit, and choose stealthedit. It will then automatically make an adjusted copy of the current page and configures the driver part to let executions of the original code go to the copy

-Auto assembler-
The stealthedit plugin adds a new auto assembler command.

stealthedit(name, address, size)

Also a new lua command: stealthedit(address,size)

How it works internally:
It hooks the pagefault and breakpoint interrupt and marks the specified memory region as non-executable
When process execution enters the affected page a pagefault will be rissen and the driver will then adjuist eip to the copy
When the execution leaves the copy it enters in a int3 field, which indicates the driver to exit the copy and return based on the location the int3 instruction happened.

The copy isn't 100% exact. For example instructions that jump beyond the int3 fields get rewritten so they jump to the original code



Known problems:
The copy stealthedit makes isn't always 100% perfect (it's based on automated disassembling and adjusting the calls, if the instructions arn't aligned properly, errors can/will occur). In case that you detect a problem (app/game crashes) inspect the copy of the memory and see what went wrong, and try to fix them yourself. Either making a full adjusted copy yourself, or just fixing the small incosistencies (e.g the first few/last instructions)

The auto assembler script part can come in use here, as name will be seen as the address of the copy, so you can use that to write the copy yourself
