<img width="1008" height="602" alt="Image" src="https://github.com/user-attachments/assets/b5d10bae-31ae-455a-a09b-ec4269c28d77" />


Hello!

This GitHub is for installing Python 3.8 / YOLO 5 and 8 on Jetson Nano.

Just follow the steps

sh file is being tested

---------------------------------------------------------------------------------------------------------------------------------

Before working, you must install opencv.


source - https://github.com/Qengineering/Install-OpenCV-Jetson-Nano

You can install the latest version of your choice. However, Please exclude 4.10.0 as an error will occur during installation.

```
#open terminal
$ wget https://github.com/Qengineering/Install-OpenCV-Jetson-Nano/raw/main/OpenCV-4-11-0.sh
$ sudo chmod 755 ./OpenCV-4-11-0.sh.
$ ./OpenCV-4-11-0.sh
```

After installation, you should do the following, because when you call the library using opencv, you get idle instructions (core dumped).

```
$ gedit ~/.bashrc

# Add to the last line.
$ export OPENBLAS_CORETYPE=ARMV8 python3

$ source ~/.bashrc
```


---------------------------------------------------------------------------------------------------------------------------------

Now, you can proceed with the installation according to the steps below "Must".

```
step 1. virtualenv and python 3.8 install guide
https://github.com/Lumi-01/Jetson-nano-yolov5-and-yolov8-install/blob/main/step%201.%20virtualenv%20and%20python%203.8%20install%20guide

step 2. yolov5 install guide
https://github.com/Lumi-01/Jetson-nano-yolov5-and-yolov8-install/blob/main/step%202.%20yolov5%20install%20guide

step 3. yolov8 install guide
(Writing..)
```

---------------------------------------------------------------------------------------------------------------------------------

sh flie (!! Not tested, Operation not guaranteed !!)

```
step 1. virtualenv and python 3.8 install
https://github.com/Lumi-01/Jetson-nano-yolov5-and-yolov8-install/blob/main/jetson_nano_Python%203.8_and_virtualenv_lnstall.sh

step 2. yolov5 install guide
https://github.com/Lumi-01/Jetson-nano-yolov5-and-yolov8-install/blob/main/jetson_nano_yolov5_lnstall.sh

step 3. yolov8 install guide
(Writing..)
```

