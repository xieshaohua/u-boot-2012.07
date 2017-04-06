#########################################################################

_depend:	.depend

# Split the source files into two camps: those in the current directory, and
# those somewhere else. For the first camp we want to support CPPFLAGS_<fname>
# and for the second we don't / can't.
PWD_SRCS := $(filter $(notdir $(SRCS)),$(SRCS))
OTHER_SRCS := $(filter-out $(notdir $(SRCS)),$(SRCS))

# This is a list of dependency files to generate
DEPS := $(basename $(patsubst %,.depend.%,$(PWD_SRCS)))

# Join all the dependencies into a single file, in three parts
#	1 .Concatenate all the generated depend files together
#	2. Add in the deps from OTHER_SRCS which we couldn't process
#	3. Add in the HOSTSRCS
.depend:	Makefile $(TOPDIR)/config.mk $(DEPS) $(OTHER_SRCS) \
		$(HOSTSRCS)
	cat /dev/null $(DEPS) >$@
	@for f in $(OTHER_SRCS); do \
		g=`basename $$f | sed -e 's/\(.*\)\.[[:alnum:]_]/\1.o/'`; \
		$(CC) -M $(CPPFLAGS) -MQ $$g $$f >> $@ ; \
	done
	@for f in $(HOSTSRCS); do \
		g=`basename $$f | sed -e 's/\(.*\)\.[[:alnum:]_]/\1.o/'`; \
		$(HOSTCC) -MQ $$g $$f >> $@ ; \
	done

MAKE_DEPEND = $(CC) -M $(CPPFLAGS) $(EXTRA_CPPFLAGS_DEP) \
		-MQ $(addsuffix .o,$(basename $<)) $< >$@


.depend.%:	%.c
	$(MAKE_DEPEND)

.depend.%:	%.S
	$(MAKE_DEPEND)

$(HOSTOBJS): %.o: %.c
	$(HOSTCC) $(HOSTCFLAGS) $(HOSTCFLAGS_$(@F)) $(HOSTCFLAGS_$(BCURDIR)) -o $@ $< -c
$(NOPEDOBJS): %.o: %.c
	$(HOSTCC) $(HOSTCFLAGS_NOPED) $(HOSTCFLAGS_$(@F)) $(HOSTCFLAGS_$(BCURDIR)) -o $@ $< -c

#########################################################################
