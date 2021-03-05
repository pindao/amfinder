# AMFinder

The Automatic Mycorrhiza Finder (AMFinder) allows for automatic computer
vision-based identification and quantification of AM fungal colonisation
and intraradical hyphal structures on ink-stained root images using
convolutional neural networks.


## Summary

1. [Command-line script (`amf`)](#amf)
2. [Standalone interface (`amfbrowser`)](#amfbrowser)

## Command-line script (`amf`)<a name="amf"></a>

The command-line script `amf` uses convolutional neural networks (ConvNets)
to predict **fungal root colonisation** and **intraradical
hyphal structures**. The program uses pre-trained networks to enable direct
analysis of ink-stained root pictures. It can also train ConvNets on
**custom datasets** to enable analysis of differently stained
or labelled root images.

### Installation instructions

`amf` requires at least **Python 3.6**. Below is a typical installation, using
a virtual environment to install dependencies:

```bash
$ python3.7 -m venv amfenv
$ source amfenv/bin/activate
(amfenv) $ python -m pip install -r requirements.txt
(amfenv) $ deactivate
```

**Note:** `amf` is not compatible with the latest Keras/Tensorflow versions due
to [a bug affecting class weights](https://github.com/tensorflow/tensorflow/issues/40457).

### Prediction mode

Predict fungal colonisation or intraradical hyphal structures within plant root images.

```bash
$ amf predict <options> <images>
```

Available options are listed below:

|Short|Long|Description|Default|
|-|-|-|-|
|`-h`|`--help`|Display this help.|
|`-t`|`--tile_size`| Tile size, in pixels.|126|
|`-net`|`--network`|Name of the pre-trained network.|None|

Several pre-trained networks are available (right-click to save):

|File name|Annotation level|Description|
|-|-|-|
|[CNN1v1.h5](amf/trained_network/CNN1v1.h5)</a>|Stage 1|Ink-stained, ClearSee-treated root pictures.|
|[CNN1v2.h5](amf/trained_network/CNN1v2.h5)|Stage 1|Same, but hue- and saturation-insensitive.|
|[CNN2v1.h5](amf/trained_network/CNN2v1.h5)|Stage 2|Ink-stained, ClearSee-treated high-magnification root pictures.|


### Training mode

Train `amf` on a different image dataset, or refine existing models.

```bash
$ amf train <options> <images>
```

Available options are listed below:

|Short|Long|Description|Default|
|-|-|-|-|
|`-h`|`--help`|Display this help.|
|`-t`|`--tile_size`| Tile size, in pixels.|126|
|`-b`|`batch_size`|Training batch size.|32|
|`-k`|`--keep_background`|Do not skip any background tile.|False|
|`-a`|`--data_augmentation`|Activate data augmentation.|False|
|`-s`|`--summary`|Save CNN architecture and graph.|False|
|`-o`|`--outdir`|Folder where to save trained model and CNN architecture.|cwd|
|`-e`|`--epochs`|Number of training cycles.|100|
|`-p`|`--patience`|Number of epochs to wait before early stopping.|12|
|`-lr`|`--learning_rate`|Learning rate used by the Adam optimiser.|0.001|
|`-vf`|`--validation_fraction`|Fraction of tiles used as validation set.|15%|
|`-1`|`--CNN1`|Train for root colonisation.|True|
|`-2`|`--CNN2`|Train for intraradical hyphal structures.|False|
|`-net`|`--network`|Name of the pre-trained network.|None|

For large datasets, running the script on a high-performance computing (HPC)
equipment is recommended. An example using [Slurm](https://slurm.schedmd.com/)
workload manager is provided below.

```bash
#! /bin/bash
#SBATCH -e train.err
#SBATCH -o train.out
#SBATCH --mem=10G
#SBATCH -n 10

BASE=/home/user/amf

source $BASE/amfenv/bin/activate
$BASE/amf train $BASE/training_data/*jpg
deactivate
```

### Diagnostic mode

Use the following command to determine **precision** and **specificity** of a
trained network:

```bash
$ amf diagnose -net <trained_network> <images>
```


## Standalone interface (`amfbrowser`)<a name="amfbrowser"></a>

The standalone interface `amfbrowser` allows to browse, amend and validate
`amf` predictions. Installation instructions are detailed below for the main
platforms.

![](doc/amfbrowser.png)

### Installation instructions<a name="amfbrowseronlinux"></a>

#### Linux

1. Download and install the OCaml package manager
[OPAM](https://opam.ocaml.org/doc/Install.html).

2. Using [`opam switch`](https://opam.ocaml.org/doc/Usage.html#opam-switch),
install **OCaml 4.08.0** (older versions won't work).

3. Install `amfbrowser` dependencies:
```bash
$ opam install dune odoc lablgtk cairo2 cairo2-gtk magic-mime camlzip
```
You may be required to install development packages, including
`libgtk2.0-dev` and `libgtksourceview2.0-dev`.

4. Retrieve `amfbrowser` sources and build:
```
$ git clone git@github.com:SchornacklabSLCU/amfinder.git
$ cd amfinder/amfbrowser
$ ./build.sh
```

5. Copy the folder `data` to your local application folder. A typical path
would be `~/.local/share/amfinder/data`.

6. The binary `amfbrowser.exe` is ready to use.


#### MacOS

Same as Linux, but you will need [Homebrew](https://brew.sh/index_fr) to
install packages.

#### Windows 10

`amfbrowser` can be installed and run on Windows 10 after activation of the
Windows Subsystem for Linux (WSL). WSL runs a a GNU/Linux environment directly
on Windows, unmodified. **Admin rights are required to activate WSL**.

1. Activate the [Windows Subsystem for Linux
(WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10). Then, go to
Windows App store and install a Linux distribution
(recommended distributions are [Ubuntu](https://ubuntu.com/) and
[Debian](https://www.debian.org/index.html), but many others should work too).

2. Install an OCaml build system based on the `brew` package manager:
```bash
$ sudo apt update
$ sudo apt upgrade
$ sudo apt autoclean
$ sudo apt install curl build-essential git
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
$ test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
$ test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
$ test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.bash_profile
$ echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.profile
$ brew install gpatch opam gtk+ cairo
```

3. Follow the [Linux installation instructions](#amfbrowseronlinux). Please note
that sandboxing does not work on Windows. OPAM should be initialized using
`opam init --disable-sandboxing`.

4. Install a X server (for instance, [Xming](https://sourceforge.net/projects/xming/)),
then configure bash to tell GUIs to use the local X server. For instance, use
`echo "export DISPLAY=localhost:0.0" >> ~/.bashrc`. Detailed instructions are
available on the internet.
