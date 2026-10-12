##################################################################################################################################################
### :::::: Pull CachyOS :::::: ###
##################################################################################################################################################
FROM ghcr.io/cmspam/cache22-cachy-kde:rolling

# :::::: prepare the kernel :::::: 
#RUN pacman -Rdd --noconfirm linux-cachyos-*
RUN rm -rf /lib/modules/*
RUN pacman -S --disable-sandbox --noconfirm linux-cachyos-deckify

# :::::: Install Packages :::::: 
RUN pacman -S --disable-sandbox --noconfirm steam


# :::::: Remove Firefox :::::: 
RUN pacman -Rdd --disable-sandbox --noconfirm firefox

RUN bootc -h
