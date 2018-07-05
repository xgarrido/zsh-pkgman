#
#cmt stuff
if [ -z "$CMTCLASS" ] ; then
    echo "CMTCLASS is undefined"
    return
else
    if [ -z "$CMTPATH" ] ; then
        export CMTPATH=${CMTCLASS}
    else
        export CMTPATH=${CMTPATH}:${CMTCLASS}
    fi
fi

if [ ! -f setup.sh ] ; then
    echo "no setup.sh found: running cmt config"
    cmt config
fi

#cmt config
source ./setup.sh
if [ -z "$CAMELROOT" ] ; then
    echo "CAMELROOT undefined ...something went wrong. do you have a requirements file?"
    return
fi

#creating link

if [ -z "${CAMEL_DATA}" ] ; then
    echo "CAMEL_DATA undefined: review your installation (see http://camel.in2p3.fr/wiki/pmwiki.php?n=Main.Install)"
    return
fi
if [ ! -d "${CAMEL_DATA}" ] ; then
    echo "empty CAMEL_DATA directory : please fix (see http://camel.in2p3.fr/wiki/pmwiki.php?n=Main.Install)"
    return
fi

echo CAMEL_DATA="${CAMEL_DATA}"
ln -sTf ${CAMEL_DATA} ${CAMELROOT}/lik/camel_data

#CLIK support
#creating link if necessary
if [ ! -z "${PLANCK_DATA}" ] ; then
    echo "PLANCK_DATA=${PLANCK_DATA}"
    ln -sTf ${PLANCK_DATA} ${CAMELROOT}/lik/planck_data
else
    echo "no PLANCK_DATA defined"
fi
if [ ! -z "$CLIKDIR" ] ; then
    source $CLIKDIR/bin/clik_profile.sh > /dev/null 2>&1
    CLIKCFLAGS=`$CLIKDIR/bin/clik-config --cflags`
    export CLIKCFLAGS
    CLIKLIBS=$($CLIKDIR/bin/clik-config --libs | sed 's/,-Bdynamic-Wl//g')
    export CLIKLIBS
    echo "CLIK support from: $CLIKDIR"
fi


if [ -n "${PICO_CODE}" ] && [ -n "${PICO_DATA}" ] ; then
    echo "PICO=${PICO_CODE} with training file=${PICO_DATA}"
    #sets your PYTHONPATH ccording to PICO_CODE
    #export PYTHONPATH=${PICO_CODE}:"$PYTHONPATH"
    export PICOINC="$(python -c "import pypico; print pypico.get_include()")"
    export PICOLIBS="$(python -c "import pypico; print pypico.get_link()")"
    #echo "includes=$PICOINC"
    #echo "libs=$PICOLIBS"
else
    echo "not using PICO"
fi

#add tools/python to PYTHONPATH
if [ -z "$PYTHONPATH" ] ; then
    PYTHONPATH=$CAMELROOT/work/tools/python
else
    PYTHONPATH=$CAMELROOT/work/tools/python:$PYTHONPATH
fi
export PYTHONPATH
#echo "PYTHONPATH=$PYTHONPATH"

#echo "Using project $CMTPATH"
cmt show uses

echo "your CAMELROOT is $CAMELROOT"

# put 1 at the end of next line if you want a closer look at compilaton
export VERBOSE=
echo "if you want more verbose compilation define VERBOSE environement variable to 1: export VERBOSE=1"
