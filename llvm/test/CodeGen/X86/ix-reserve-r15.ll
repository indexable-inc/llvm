; RUN: llc -mtriple=x86_64-unknown-linux-gnu -x86-reserve-r15 < %s | FileCheck %s
; RUN: llc -mtriple=x86_64-unknown-linux-gnu < %s | FileCheck %s --check-prefix=STOCK

; -x86-reserve-r15 (ix fork): r15 is a pinned global (the wasm linear-memory
; base in ix-aot). It is never allocated, saved or restored, and a value
; written with llvm.write_register survives to the callee of a tail call.

define i64 @pressure(i64 %a, i64 %b) nounwind {
; CHECK-LABEL: pressure:
; CHECK-NOT:   %r15
; CHECK:       retq
; STOCK-LABEL: pressure:
; STOCK:       pushq %r15
  %x = add i64 %a, %b
  call void asm sideeffect "", "~{rax},~{rbx},~{rcx},~{rdx},~{rsi},~{rdi},~{rbp},~{r8},~{r9},~{r10},~{r11},~{r12},~{r13},~{r14}"()
  ret i64 %x
}

declare tailcc void @body(ptr)

define void @entry(ptr %vm, i64 %base) nounwind {
; CHECK-LABEL: entry:
; CHECK-NOT:   pushq %r15
; CHECK:       movq %rsi, %r15
; CHECK-NOT:   popq %r15
; CHECK:       {{callq|jmp}} body
  call void @llvm.write_register.i64(metadata !0, i64 %base)
  tail call tailcc void @body(ptr %vm)
  ret void
}

define i64 @read() nounwind {
; CHECK-LABEL: read:
; CHECK:       movq %r15, %rax
  %v = call i64 @llvm.read_register.i64(metadata !0)
  ret i64 %v
}

declare void @llvm.write_register.i64(metadata, i64)
declare i64 @llvm.read_register.i64(metadata)

!0 = !{!"r15"}
