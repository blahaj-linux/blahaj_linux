!/bin/bash


printf_green()  { printf "\033[32m$1\033[0m\n"; }
printf_yellow() { printf "\033[33m$1\033[0m\n"; }
printf_red()    { printf "\033[31m$1\033[0m\n"; }
printf_grey()   { printf "\033[37m$1\033[0m\n"; }

packages=(
  "bash"
  "binutils"
  "bison"
  "coreutils"
  "diffutils"
  "findutils"
  "gawk"
  "gcc"
  "g++"
  "grep"
  "gzip"
  "m4"
  "make"
  "patch"
  "perl"
  "python3"
  "sed"
  "tar"
  "texinfo"
  "xz-utils"
)
min_version=(
  "3.2"            # Bash
  "2.13.1"         # Binutils
  "2.7"            # Bison
  "6.9"            # Coreutils
  "2.8.1"          # Diffutils
  "4.2.31"         # Findutils
  "4.0.1"          # Gawk
  "4.8"            # GCC
  "4.8"            # g++
  "2.5.1a"         # Grep
  "1.3.12"         # Gzip
  "1.4.10"         # M4
  "4.0"            # Make
  "2.5.4"          # Patch
  "5.8.8"          # Perl
  "3.4"            # Python
  "4.1.5"          # Sed
  "1.22"           # Tar
  "4.7"            # Texinfo
  "5.0.0"          # Xz
)
max_version=(
  ""               # Bash
  "2.39"           # Binutils
  ""               # Bison
  ""               # Coreutils
  ""               # Diffutils
  ""               # Findutils
  ""               # Gawk
  "12.2.0"         # GCC
  "12.2.0"         # g++
  ""               # Grep
  ""               # Gzip
  ""               # M4
  ""               # Make
  ""               # Patch
  ""               # Perl
  ""               # Python
  ""               # Sed
  ""               # Tar
  ""               # Texinfo
  ""               # Xz
)
links=(
  "/bin/sh"        # Bash
  ""               # Binutils
  "/usr/bin/yacc"  # Bison
  ""               # Coreutils
  ""               # Diffutils
  ""               # Findutils
  "/usr/bin/awk"   # Gawk
  ""               # GCC
  ""               # g++
  ""               # Grep
  ""               # Gzip
  ""               # M4
  ""               # Make
  ""               # Patch
  ""               # Perl
  ""               # Python
  ""               # Sed
  ""               # Tar
  ""               # Texinfo
  ""               # Xz
)
error_list=()










printf_grey "Checking that apt is installed"
if ! command -v apt &> /dev/null
then
    printf_red "apt is not installed"
    exit 1
fi
printf_green "apt is installed"
printf_grey "Checking that dpkg is installed"
if ! command -v dpkg &> /dev/null
then
    printf_red "dpkg is not installed"
    exit 1
fi
printf_green "dpkg is installed"





for package in "${packages[@]}"; do
  printf_grey "Checking that $package is installed"
  if ! dpkg -s "$package" >/dev/null 2>&1; then
    printf_yellow "Package ${package} is not installed."
    printf_yellow "attempting to install ${package}"
    sudo apt-get install "$package"
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      printf_red "Package ${package} is not installed."
      printf_red "Please install ${package} and try again."
      error_list+=("${package} is not installed. and could not be installed. Please install ${package} and try again.")
      unset packages[$i]
      unset min_version[$i]
      unset max_version[$i]
      unset links[$i]
    fi
  else
    printf_green "Package ${package} is installed."
  fi
done



declare -a installed_version=()
declare -a candidate_version=()
for i in "${!packages[@]}"; do
  printf_grey "checking installed version of ${packages[$i]}"
  installed_version[$i]=$( apt-cache policy "${packages[$i]}" | grep -oP '(?<=Installed: ).*' | cut -d' ' -f1| cut -d':' -f2)
  printf_grey "checking candidate version of ${packages[$i]}"
  candidate_version[$i]=$( apt-cache policy "${packages[$i]}" | grep -oP '(?<=Candidate: ).*' | cut -d' ' -f1| cut -d':' -f2)
done


for i in "${!packages[@]}"; do
  if [[ "${max_version[$i]}" != "" ]]; then
    printf_grey "checking if ${packages[$i]} installed version is exceeds the maximum version"
    if dpkg --compare-versions "${installed_version[$i]}" gt "${max_version[$i]}"; then
      printf_yellow "Installed version of ${packages[$i]}  (${installed_version[$i]}) is greater than the max version of ${max_version[$i]}."
      printf_yellow "Attempting to downgrade ${packages[$i]} to ${max_version[$i]}."
      sudo apt-get install "${packages[$i]}=${max_version[$i]}"
      if dpkg --compare-versions "${installed_version[$i]}" gt "${max_version[$i]}"; then
        printf_red "Installed version of ${packages[$i]}  (${installed_version[$i]}) is greater than the max version of ${max_version[$i]}."
        printf_red "Please downgrade ${packages[$i]} to ${max_version[$i]} and try again."
        error_list+=("Installed version of ${packages[$i]}  (${installed_version[$i]}) is greater than the max version of ${max_version[$i]}. Please downgrade ${packages[$i]} to ${max_version[$i]} and try again.")
        unset packages[$i]
        unset min_version[$i]
        unset max_version[$i]
        unset links[$i]
      else
        installed_version[$i]="${max_version[$i]}"
      fi
    else
      printf_green "Installed version of ${packages[$i]}  does not exceed the maximum version"
    fi
      printf_grey "checking if ${packages[$i]} is up to date"
      if [[ "${installed_version[$i]}" != "${candidate_version[$i]}" ]]; then
        printf_grey "checking if ${packages[$i]} update exceeds the maximum version"
        if dpkg --compare-versions "${candidate_version[$i]}" gt "${max_version[$i]}"; then
          if dpkg --compare-versions "${installed_version[$i]}" lt "${max_version[$i]}"; then
            printf_yellow "attempting to update ${packages[$i]} to ${max_version[$i]}."
            sudo apt-get install "${packages[$i]}=${max_version[$i]}"
            if dpkg --compare-versions "${installed_version[$i]}" lt "${max_version[$i]}"; then
              printf_yellow "couldn't update ${packages[$i]} to ${max_version[$i]}. But this is a not a critical error."
              candidate_version[$i]= "${installed_version[$i]}"
            else
              installed_version[$i]="${max_version[$i]}"
            fi
          fi
        else
          printf_green "update of ${packages[$i]} does not exceed the maximum version"
        fi
      else
        printf_green "${packages[$i]} is up to date"
      fi
  fi
  printf_grey "checking if ${packages[$i]} is up to date"
  if dpkg --compare-versions "${candidate_version[$i]}" gt "${installed_version[$i]}"; then
    printf_yellow "attempting to update ${packages[$i]} to ${candidate_version[$i]}."
    sudo apt-get install "${packages[$i]}=${candidate_version[$i]}"
    if dpkg --compare-versios "${candidate_version[$i]}" gt "${installed_version[$i]}"; then
      printf_yellow "couldn't update ${packages[$i]} to ${candidate_version[$i]}. But this is a not a critical error."
      candidate_version[$i]= "${installed_version[$i]}"
    else
      installed_version[$i]="${candidate_version[$i]}"
    fi
  else
    printf_green "${packages[$i]} is up to date."
  fi
  if [[ "${min_version[$i]}" != "" ]]; then
    printf_grey "checking if the minimum version requirement of ${packages[$i]} is met"
    if dpkg --compare-versions "${installed_version[$i]}" lt "${min_version[$i]}"; then
      printf_red "Installed version of ${packages[$i]}  (${installed_version[$i]}) is less than the min version of ${min_version[$i]}."
      printf_red "Please update ${packages[$i]} to ${min_version[$i]} and try again."
      error_list+=("Installed version of ${packages[$i]}  (${installed_version[$i]}) is less than the min version of ${min_version[$i]}. Please update ${packages[$i]} to ${min_version[$i]} and try again.")
      unset packages[$i]
      unset min_version[$i]
      unset max_version[$i]
      unset links[$i]
    else
      printf_green "Minimum version requirement for ${packages[$i]} is met."
    fi
  fi
  if [[ "${links[$i]}" != "" ]]; then
    printf_grey "checking if ${packages[$i]} is linked to ${links[$i]}"
    if [ $(which "${packages[$i]}") != $(readlink -f "${links[$i]}") ] && [ ! -L /usr/bin/${packages[i]} ]; then
      printf_yellow "attempting to create a symlink for ${packages[$i]}."
      sudo ln -sf "${links[$i]}" $(readlink -f "${links[$i]}")
      if [ $(which "${packages[$i]}") != $(readlink -f "${links[$i]}") ] && [ ! -L /usr/bin/${packages[i]} ]; then
        printf_red "couldn't create a symlink for ${packages[$i]}"
        error_list+=("couldn't create a symlink for ${packages[$i]}")
        unset packages[$i]
        unset min_version[$i]
        unset max_version[$i]
        unset links[$i]
        else
          printf_green "${packages[$i]} has been linked to ${links[$i]}"
      fi
    else
      printf_green "${packages[$i]} is linked to ${links[$i]}"
    fi
  fi
done


if [[ "${#error_list[@]}" -gt 0 ]]; then
  printf_red "You are not ready to start LFS. Please fix the following errors and try again."
  for error in "${error_list[@]}"; do
    printf_red "${error}"
  done
  exit 1
else
  printf_green "You are ready to start LFS."
  exit 0
fi


