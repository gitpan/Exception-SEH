#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "hook_op_check.h"

STATIC OP *
unwind_return (pTHX_ OP *op, void *user_data) {
  SV* unwind_flag;

  unwind_flag = get_sv("Exception::SEH::need_unwind", FALSE);
  if (!unwind_flag)
		croak("Unwind flag not initialized!");

  sv_setiv(unwind_flag, 1);

  return CALL_FPTR ((OP *(*)(pTHX))user_data) (aTHX);
}

/* Hook the OP_RETURN iff we are in the same file as originally compiling. */
STATIC OP* check_return (pTHX_ OP *op, void *user_data) {
  const char* file = SvPV_nolen( (SV*)user_data );
  const char* cur_file = CopFILE(&PL_compiling);

  if (strcmp(file, cur_file))
    return op;

  hook_op_ppaddr(op, unwind_return, op->op_ppaddr);
  return op;
}

MODULE = Exception::SEH PACKAGE = Exception::SEH::XS
PROTOTYPES: DISABLE

void
install_return_op_check()
  CODE:
    /* Code stole from Scalar::Util::dualvar */
    UV id;
    char* file = CopFILE(&PL_compiling);
    STRLEN len = strlen(file);

    ST(0) = newSV(0);

    (void)SvUPGRADE(ST(0),SVt_PVNV);
    sv_setpvn(ST(0),file,len);

    id = hook_op_check(OP_RETURN, check_return, ST(0));
#ifdef SVf_IVisUV
    SvUV_set(ST(0), id);
    SvIOK_on(ST(0));
    SvIsUV_on(ST(0));
#else
    SvIV_set(ST(0), id);
    SvIOK_on(ST(0));
#endif

    XSRETURN(1);

void
uninstall_return_op_check(id)
SV* id
  CODE:
#ifdef SVf_IVisUV
    UV uiv = SvUV(id);
#else
    UV uiv = SvIV(id);
#endif
    hook_op_check_remove(OP_RETURN, uiv);
  OUTPUT:

