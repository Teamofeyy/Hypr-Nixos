{ host, ... }:
let
  inherit (import ../../../hosts/${host}/variables.nix) gitEmail gitUsername;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "no";
      Compression = false;
      ForwardAgent = false;
      HashKnownHosts = false;
      ServerAliveCountMax = 3;
      ServerAliveInterval = 0;
      UserKnownHostsFile = "~/.ssh/known_hosts";
    };
    extraConfig = ''
      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/github
        IdentitiesOnly yes
        AddKeysToAgent yes

      Host gitlab.com gitlab.* *.gitlab.* gitlab.internal.madrigal.ru
        User git
        IdentityFile ~/.ssh/gitlab
        IdentitiesOnly yes
        AddKeysToAgent yes
    '';
  };

  programs.git = {
    enable = true;
    signing.format = null;

    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:**";
        contents.user = {
          name = "Teamofeyy";
          email = "timarnd06@gmail.com";
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        contents.user = {
          name = "Teamofeyy";
          email = "timarnd06@gmail.com";
        };
      }
      {
        condition = "hasconfig:remote.*.url:ssh://git@gitlab.internal.madrigal.ru/**";
        contents.user = {
          name = "Тимофей Марченко";
          email = "t.marchenko@madrigal.expert";
        };
      }
      {
        condition = "hasconfig:remote.*.url:git@gitlab.internal.madrigal.ru:**";
        contents.user = {
          name = "Тимофей Марченко";
          email = "t.marchenko@madrigal.expert";
        };
      }
      {
        condition = "hasconfig:remote.*.url:https://gitlab.internal.madrigal.ru/**";
        contents.user = {
          name = "Тимофей Марченко";
          email = "t.marchenko@madrigal.expert";
        };
      }
    ];

    settings = {
      user = {
        name = gitUsername;
        email = gitEmail;
      };
      push.default = "simple"; # Match modern push behavior
      push.autoSetupRemote = true;
      credential.helper = "cache --timeout=7200";
      init.defaultBranch = "main"; # Set default new branches to 'main'
      log.decorate = "full"; # Show branch/tag info in git log
      log.date = "iso"; # ISO 8601 date format
      # Conflict resolution style for readable diffs
      merge.conflictStyle = "diff3";
      core.editor = "nvim";
      diff.colorMoved = "default";
      merge.stat = "true";
      core.whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";

      url = {
        "git@github.com:" = {
          insteadOf = [
            "https://github.com/"
            "ssh://git@github.com/"
          ];
        };

        "git@gitlab.com:" = {
          insteadOf = [
            "https://gitlab.com/"
            "ssh://git@gitlab.com/"
          ];
        };

        "ssh://git@gitlab." = {
          insteadOf = [
            "https://gitlab."
            "http://gitlab."
          ];
        };

        "ssh://git@gitlab.internal.madrigal.ru/" = {
          insteadOf = [
            "https://gitlab.internal.madrigal.ru/"
            "http://gitlab.internal.madrigal.ru/"
          ];
        };
      };

      alias = {
        br = "branch --sort=-committerdate";
        co = "checkout";
        af = "!git add $(git ls-files -m -o --exclude-standard | fzf -m)";
        com = "commit -a";
        ca = "commit -a";
        df = "diff";
        gs = "stash";
        gp = "pull";
        st = "status";
        lg = "log --graph --pretty=format:'%Cred%h%Creset - %C(yellow)%d%Creset %s %C(green)(%cr)%C(bold blue) <%an>%Creset' --abbrev-commit";
        edit-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; hx `f`";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      true-color = "never";

      features = "unobtrusive-line-numbers decorations";
      unobtrusive-line-numbers = {
        line-numbers = true;
        line-numbers-left-format = "{nm:>4}│";
        line-numbers-right-format = "{np:>4}│";
        line-numbers-left-style = "grey";
        line-numbers-right-style = "grey";
      };
      decorations = {
        commit-decoration-style = "bold grey box ul";
        file-style = "bold blue";
        file-decoration-style = "ul";
        hunk-header-decoration-style = "box";
      };
    };
  };
}
