- NOTE: using this image will slightly change how ostree and grub works, so there is no way to rebase back to bazzite. please backup your stuff.
- NOTE2: rebasing to this is NOT recommended. you have been warned.

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
  yes.
  all changes I made are in the Containerfile. go nuts.
  I will not provide ANY help. you are on your own.
  ```

- I found a bug!
  ```
  here's a cookie.
  ```
  
- Can I haz secureboot? 
  ```
  not recommend. secureboot cannot be turned off on the Steamdeck (there's no option in the bios to turn it off) so if you do that, you're stuck.
  ```

- Can I haz selinux? 
    ```
  yes. 
    ```


- I'm using this and experiencing no issues whatsoever, this is actually very smooth.
  ```
  cheers!
  ```

#|

# how do I install this abomination?

- step 1 - install bazzite. (bazzite.gg) 
- step 2 - boot into bazzite and run the following commands: 
```
ostree-image-signed:docker://ghcr.io/chucktripwell/frankengold-handheld:latest
```
- step 3 - reboot
- step 4 - regret.

that's it!
your gaming handheld is now running frankengold.

(or, if you got confused and ran the desktop version by accident, you are now bricked.) 

to verify, run:
```
fastfetch
```

if the kernel does not have "fc" or "bazzie" anywhere, you are on frankengold. 
