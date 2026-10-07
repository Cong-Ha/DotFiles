# Login shells read this file (not .bashrc). Source .bashrc so interactive
# config (oh-my-posh prompt, aliases) loads for `bash --login` too.
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
