# How to build oclint_23.00

* Download source code of [oclint/support_xcode14](https://github.com/Lianghuajian/oclint/tree/support_xcode14)
* Build and make
    ```
    cd oclint-scripts
    ./make
    # build/oclint-release is the production
    ```
* Copy `build/oclint-release` to `/opt/homebrew/Cellar/`(or any other directory you like), and export path to `~/.bash_profile`:
    ```
    export PATH=$PATH:/opt/homebrew/Cellar/oclint/23.00/bin:
    ```
* To use in CodeLint target, copy `build/oclint-release` to `Tools` directory and rename it to oclint_23.00