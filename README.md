- NOTE1: using this image will slightly change permissios and such, so there might be no way to rebase back to bazzite (this might be fixed at a future date) so please backup your stuff.

- NOTE2: this OS was made for my own amusement. rebasing to this is NOT recommended. you have been warned.

- NOTE3: This OS is my daily driver...  Everywhere I looked it says this will not harm your ssd or cooling system, which is good enough for me...
if YOU believe there's even a slight chance it might harm YOUR hardware, do not install this OS!!!

# Frankengold Linux - Handheld
--- you did WHAT?!?! ---

- What is this?
```
bazzite-handheld image but with an archlinux kernel optimized for gaming.
```

- Is it safe?
```
probably not.
```

- Then, why?
```
in theory: the speed of cachyos, the stability of bazzite.
in practice: It's my device, I'll do what I want with it.
```

- Can you add this feature...?
```
no.
```

- Can I create my own version?
```
sure, 
I will not provide ANY help tough. so you are on your own.
```

- I found a bug!
```

here's a cookie.
```
  
- Can I haz secureboot? 
```
not recommend. secureboot cannot be turned off on the Steamdeck (there's no option in the bios to turn it off) so if you do that, you're forever stuck, unable to install any other OS. very scary.
```

- Can I haz selinux? 
```
  yes.
```


- I'm using this OS as a daily driver and experiencing no issues whatsoever, this is actually very smooth.
```
cheers!
```

#

# how do I install this abomination?

- NOTE: this was tested only on the Steamdeck LCD, as it's the only handheld I own. it willprobably run fine on other handhelds with a GPU that's not from Nvidia.

- step 1 - install bazzite as usual (https://bazzite.gg). 
- step 2 - take a deep breath, reconsider your life choices, boot into bazzite and run the following commands: 
```
ostree-image-signed:docker://ghcr.io/chucktripwell/frankengold-handheld:latest
```
- step 3 - reboot, regret.
- step 4 - good luck!

that's it!
your gaming handheld is now running frankengold.

(or, if you got confused and ran the desktop version by accident, you are now bricked.) 

to verify the installation, run:
```
fastfetch
```

if the kernel does not have "fc" or "bazzie" anywhere, you are probably on frankengold. 
if it says "cachyos", you are definitely on frankengold. enjoy. 


