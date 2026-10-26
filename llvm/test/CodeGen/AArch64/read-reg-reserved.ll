; RUN: llc -mtriple=aarch64-linux-gnu -mattr=+reserve-x21 -verify-machineinstrs < %s | FileCheck %s

; A read of a reserved register (here x21, pinned as a memory base) is a plain
; COPY, which the register coalescer folds into its users, in any block (the
; two reads below become one). Only reads of allocatable registers (the MSVC
; __getReg intrinsics) need the READ_REGISTER_GPR64 pseudo, which costs a mov
; per read.

define i64 @add_base(i64 %a) {
; CHECK-LABEL: add_base:
; CHECK:       // %bb.0:
; CHECK-NEXT:    add x0, x21, x0
; CHECK-NEXT:    ret
  %b = call i64 @llvm.read_register.i64(metadata !0)
  %r = add i64 %b, %a
  ret i64 %r
}

define i32 @load_base(i1 %c, i64 %i, i64 %j) {
; CHECK-LABEL: load_base:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    tst w0, #0x1
; CHECK-NEXT:    csel x8, x1, x2, ne
; CHECK-NEXT:    ldr w0, [x21, x8]
; CHECK-NEXT:    ret
entry:
  br i1 %c, label %then, label %else
then:
  %b0 = call i64 @llvm.read_register.i64(metadata !0)
  %a0 = add i64 %b0, %i
  %p0 = inttoptr i64 %a0 to ptr
  %v0 = load i32, ptr %p0
  ret i32 %v0
else:
  %b1 = call i64 @llvm.read_register.i64(metadata !0)
  %a1 = add i64 %b1, %j
  %p1 = inttoptr i64 %a1 to ptr
  %v1 = load i32, ptr %p1
  ret i32 %v1
}

; Not reserved: still the pseudo's mov.
define i64 @x5_not_reserved() {
; CHECK-LABEL: x5_not_reserved:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov x0, x5
; CHECK-NEXT:    ret
  %v = call i64 @llvm.read_register.i64(metadata !1)
  ret i64 %v
}

declare i64 @llvm.read_register.i64(metadata)

!0 = !{!"x21"}
!1 = !{!"x5"}
