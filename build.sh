#UPDATE REPOS
sudo yum check-update
sudo apt-get update

#INSTALL GIT
sudo apt-get -y install git 
sudo yum -y install git

LINUX_ID=`cat /etc/os-release | egrep -i -o "^ID=(.*)" | egrep -io "[a-z]*" | grep -v ID`
LINUX_ID_LIKE=`cat /etc/os-release | egrep -i -o "^ID_LIKE=(.*)" | egrep -io "[a-z]*" | egrep -v '(ID|LIKE)'`
LINUX_VERSION_ID=`cat /etc/os-release | egrep -i -o "^VERSION_ID=(.*)" | egrep -io "[0-9\.]*"`
echo "LINUX_ID=$LINUX_ID"
echo "LINUX_ID_LIKE=$LINUX_ID_LIKE"
echo "LINUX_VERSION_ID=$LINUX_VERSION_ID"

#Install lbzip2, RED HAT seems to need this
#http://lbzip2.org/download
if which lbzip2 >/dev/null; then
	echo "lbzip2 exists (http://lbzip2.org/download)"
else
	if [ "$LINUX_ID" = "rhel" ]; then 
		echo "Installing lbzip2 (http://lbzip2.org/download)"
		sudo yum -y  groupinstall 'Development Tools'
		curl -O http://archive.lbzip2.org/lbzip2-2.5.tar.gz
		tar -xvzf lbzip2-2.5.tar.gz
		cd lbzip2-2.5
		./configure
		make check
		sudo make install
		cd ..
	else
		echo "Missing lbzip2 (http://lbzip2.org/download)"
	fi;
fi


#install gtk2.0, UBUNTU seems to need this
if [ "$LINUX_ID" = "ubuntu" ]; then 
	sudo apt-get install -y gtk2.0

	#Install python27, Ubuntu 16 seems to need this
	if which python2.7 >/dev/null; then
		echo "python2.7 exists"
	else
		echo "Installing python 2.7"
		sudo apt-get install -y python-minimal
	fi
fi;



#INSTALL DEPOT TOOLS
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=`pwd`/depot_tools:"$PATH"

#ADD DEPOT TOOLS PATH PERMANENTLY
echo 'export PATH='`pwd`'/depot_tools:"$PATH"' >> ~/.profile

#DOWNLOAD AND CHECKOUT SOURCE CODE
mkdir webrtc-checkout
cd webrtc-checkout
fetch --nohooks webrtc
gclient sync
cd src
git checkout master

#BUILDING
#NOTICE: Debug builds are component builds (shared libraries) 
#by default unless is_component_build=false is passed to gn gen --args. 
#Release builds are static by default.
#To generate ninja project files for a Release build instead:

#DEFAULT DEBUG BUILD
#gn gen out/Debug
#generate optional qt creator project files
gn gen out/Debug

#OPTIONAL RELEASE BUILD
#gn gen out/Release --args='is_debug=false'
#gn gen out/Release --args='is_debug=false' --ide="qtcreator" 

#THIS IS THE COMMAND TO CLEAN THE BUILD
#To clean all build artifacts in a directory but leave the current GN configuration untouched (stored in the args.gn file), do:
#gn clean out/Debug
#gn clean out/Release

#COMPILE
ninja -C out/Debug
