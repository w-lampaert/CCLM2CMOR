#/bin/bash -l

### printing functions
# Function for verbose printing
function echov {
  if ${v}; then
      echo $1
  fi
}

# Function for regular printing
function echon {
  if ${n}; then
       echo $1
  fi
}

