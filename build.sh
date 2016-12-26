LINUX_ID=`cat /etc/os-release | egrep -i -o "^ID=(.*)" | egrep -io "[a-z]*" | grep -v ID`
LINUX_ID_LIKE=`cat /etc/os-release | egrep -i -o "^ID_LIKE=(.*)" | egrep -io "[a-z]*" | egrep -v '(ID|LIKE)'`
LINUX_VERSION_ID=`cat /etc/os-release | egrep -i -o "^VERSION_ID=(.*)" | egrep -io "[0-9\.]*"`
LINUX_MAJOR_VERSION_ID=`cat /etc/os-release | egrep -io "^VERSION_ID=.[0-9]*" | egrep -io "[0-9]*"`

echo "LINUX_ID=$LINUX_ID"
echo "LINUX_ID_LIKE=$LINUX_ID_LIKE"
echo "LINUX_VERSION_ID=$LINUX_VERSION_ID"
echo "LINUX_MAJOR_VERSION_ID=$LINUX_MAJOR_VERSION_ID"


#UBUNTU
if [ "$LINUX_ID" = "ubuntu" ]; then 
	sudo apt-get update
	sudo apt-get -y install git
	sudo apt-get -y install lbzip2
	sudo apt-get install -y gtk2.0

	#PYTHON2.7 
	if which python2.7 >/dev/null; then
		echo "python2.7 exists"
	else
		echo "Installing python 2.7"
		sudo apt-get install -y python-minimal
	fi
fi;



#REDHAT
if [ "$LINUX_ID" = "rhel" ]; then 
	sudo yum check-update
	sudo yum -y install git

	#LBZIP2
	if which lbzip2 >/dev/null; then
		echo "lbzip2 exists (http://lbzip2.org/download)"
	else
		echo "Installing lbzip2 (http://lbzip2.org/download)"
		sudo yum -y  groupinstall 'Development Tools'
		curl -O http://archive.lbzip2.org/lbzip2-2.5.tar.gz
		tar -xvzf lbzip2-2.5.tar.gz
		cd lbzip2-2.5
		./configure
		make check
		sudo make install
		cd ..
	fi;
fi;




#SUSE 
if [ "$LINUX_ID" = "sles" ]; then 
	#UPDATE REPOS
	sudo zypper --non-interactive refresh 
	sudo zypper --non-interactive install git

	#LBZIP2
	if which lbzip2 >/dev/null; then
		echo "lbzip2 exists (http://lbzip2.org/download)"
	else
		echo "Installing lbzip2 (http://lbzip2.org/download)"
		sudo zypper --non-interactive install gcc gcc-c++
		wget http://archive.lbzip2.org/lbzip2-2.5.tar.gz
		tar -xvzf lbzip2-2.5.tar.gz
		cd lbzip2-2.5
		./configure
		make check
		sudo make install
		cd ..
	fi;

	#PYTHON2.7
	if which python2.7 >/dev/null; then
		echo "python2.7 exists"
	else
		echo "Installing python 2.7"
		sudo zypper --non-interactive install gcc gcc-c++
		sudo zypper --non-interactive install openssl-devel

		#this repo is for SUSE 11 only
		sudo zypper --non-interactive addrepo http://download.opensuse.org/repositories/devel:/tools:/scm:/svn:/1.8/SLE_11_SP4/devel:tools:scm:svn:1.8.repo
		
		wget http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tgz
		tar xvfz Python-2.7.3.tgz # unzip
		cd Python-2.7.3
		./configure
		make
		sudo make altinstall
		cd ..
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
gn gen out/Debug --ide="qtcreator" 

#OPTIONAL RELEASE BUILD
#gn gen out/Release --args='is_debug=false'
#gn gen out/Release --args='is_debug=false' --ide="qtcreator" 

#THIS IS THE COMMAND TO CLEAN THE BUILD
#To clean all build artifacts in a directory but leave the current GN configuration untouched (stored in the args.gn file), do:
#gn clean out/Debug
#gn clean out/Release

#COMPILE
ninja -C out/Debug
