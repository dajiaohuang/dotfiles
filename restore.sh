#!/usr/bin/env bash

###########################
# This script restores backed up dotfiles
# @author Adam Eivy
###########################

# Resolve paths from this script so it can be launched from any directory.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
source "$ROOT_DIR/lib_sh/echos.sh"
source "$ROOT_DIR/lib_sh/requirers.sh"

if [[ -z $1 || "$1" == */* || "$1" == "." || "$1" == ".." ]]; then
  error "specify a backup folder name from ~/.dotfiles_backup/ (not a path)."
  exit 1
fi

BACKUP_DIR="$HOME/.dotfiles_backup/$1"
if [[ ! -d "$BACKUP_DIR" ]]; then
  error "backup folder does not exist: $BACKUP_DIR"
  exit 1
fi

bot "Do you wish to change your shell back to bash?"
read -r -p "[Y|n] " response

if [[ $response =~ ^(no|n|N) ]];then
    bot "ok, leaving shell as zsh..."
else
    bot "ok, changing shell to bash..."
    chsh -s "$(command -v bash)" || exit 1
fi

bot "Restoring dotfiles from backup..."

# The installer stores dotfiles inside the selected backup directory. Restore
# only those entries, and never follow or delete an unrelated HOME entry.
for backup_file in "$BACKUP_DIR"/.[!.]* "$BACKUP_DIR"/..?*; do
  # Bash leaves an unmatched glob unchanged; skip it and any non-restorable entry.
  [[ -e "$backup_file" || -L "$backup_file" ]] || continue

  file="${backup_file##*/}"
  target="$HOME/$file"
  running "$target"

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ ! -L "$target" ]]; then
      error "refusing to overwrite existing non-symlink: $target (backup retained)"
      continue
    fi
    link_target="$(readlink "$target")" || {
      error "could not inspect symlink: $target (backup retained)"
      continue
    }
    if [[ "$link_target" != "$ROOT_DIR/homedir/$file" && "$link_target" != "$HOME/.dotfiles/homedir/$file" ]]; then
      error "refusing to remove unmanaged symlink: $target (backup retained)"
      continue
    fi
    rm "$target" || {
      error "could not remove managed symlink: $target (backup retained)"
      continue
    }
  fi

  if mv "$backup_file" "$target"; then
    echo -en "$1 backup restored";ok
  else
    error "could not restore $file; backup retained at $backup_file"
  fi
  echo -en '\done';ok
done

bot "Woot! All done."
