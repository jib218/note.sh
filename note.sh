#!/bin/sh

NOTE_DIR=~/notes
NOTE_EDITOR=vim

function note {
    case $1 in 
        "")         
                    ls $NOTE_DIR 
                    ;;    
        "help" | "-h")
                    note-help
                    ;;
        "init")     
                    note-init "$2"
                    ;;
        "add")      
                    note-add "$2"
                    ;;
        "purge")    
                    note-purge "${@:2}"
                    ;;
        "view")  
                    if [ "$2" == "all" ]
                    then
                        note-view-all
                    else 
                        note-view "${@:2}"
                    fi 
                    ;;
        "search")   
                    note-search "$2"
                    ;;
        "sync")     
                    note-sync "$2"
                    ;;
        *)          
                    note-edit "$1" 
                    ;;
    esac
}   

function note-help {
    echo "usage: note                    Lists all taken notes."
    echo "       note init [remote]      Initializes NOTE_DIR and git repo."
    echo "       note add <name>         Adds a new note or opens an existing one."
    echo "       note <name>             Opens an existing note with the"
    echo "                               NOTE_EDITOR (default: vim)."
    echo "       note purge <names>      Purges notes."
    echo "       note view <names>       Executes pandoc with the specified note names."
    echo "                               Pandoc generates html that is viewed with lynx."
    echo "       note view all           Executes pandoc with all notes."
    echo "                               Pandoc generates html that is viewed with lynx."                             
    echo "       note search <regex>     Searches all md files within NOTE_DIR"
    echo "                               with grep -n -i -r."
    echo "       note sync [commitmsg]   Executes git pull, add, commit, and push."
    echo "                               Omits pull and push if there is no remote given. " 
    echo "                               Commit message is optional."
    echo ""
    echo "Notes are saved as markdown text files inside the NOTE_DIR."
}

function note-init {
    mkdir -p $NOTE_DIR
    git init $NOTE_DIR
    if [ -z "$1" ]
    then
        echo "no remote set"      		
       	return
    fi
    git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR remote add origin "$1"
}

function note-add {
    local longtitle="$1"
    local filename=${1// /-}
    filename=${filename,,}
    if [ ! -f "$NOTE_DIR/$filename.md" ]
    then
        { 
            echo "# $longtitle {#$filename}" 
            echo "" 
            echo "" 
        } > "$NOTE_DIR/$filename.md"
    fi
    $NOTE_EDITOR "$NOTE_DIR/$filename.md"
}

function note-purge {
    for i in "$@"
    do
        local filename=${i// /-}
        filename=${filename,,}
        rm "$NOTE_DIR/$filename.md"
    done
}

function note-view-all {
    pandoc -s --toc $NOTE_DIR/*.md | lynx -stdin
}

function note-view {
    if [ -z "$@" ]
    then
        echo "no note specified"     		
       	return
    fi

    local params=""
    for i in "$@"
    do
        local filename=${i// /-}
        filename=${filename,,}
        params="$params $NOTE_DIR/$filename.md"
    done

    pandoc -s --toc $params | lynx -stdin
}


function note-search {
    if [ -z "$1" ]
    then
        echo "no search string"     		
       	return
    fi
    grep -n -i -r "$1" $NOTE_DIR --include=\*.md
}

function note-sync {
    local numberRemotes=$(git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR \
                    remote -v | wc -l)
    if [ $numberRemotes -ne 0 ]
    then
        git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR pull origin master
    fi

    # Add
    git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR add -A

    # Commit
    if [ -z "$1" ]
    then
        git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR commit -m "note-sync"
    else
        git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR commit -m "$1"
    fi

    if [ $numberRemotes -ne 0 ]
    then
        git --git-dir=$NOTE_DIR/.git --work-tree=$NOTE_DIR push origin master
    fi
}

function note-edit {
    local filename=${1// /-}
    filename=${filename,,}
    if [ -f "$NOTE_DIR/$filename.md" ]
    then
        $NOTE_EDITOR "$NOTE_DIR/$filename.md"
    else
        echo "note does not exist"
    fi
}
