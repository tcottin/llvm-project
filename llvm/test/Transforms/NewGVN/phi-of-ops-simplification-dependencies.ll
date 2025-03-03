; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes=newgvn -S %s | FileCheck %s

declare void @use.i16(ptr)
declare void @use.i32(i32)

; Test cases from PR35074, where the simplification dependencies need to be
; tracked for phi-of-ops root instructions.

define void @test1(i1 %arg) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_COND:%.*]]
; CHECK:       for.cond:
; CHECK-NEXT:    [[PHIOFOPS:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[Y_0:%.*]], [[FOR_INC6:%.*]] ]
; CHECK-NEXT:    [[Y_0]] = phi i32 [ 1, [[ENTRY]] ], [ [[INC7:%.*]], [[FOR_INC6]] ]
; CHECK-NEXT:    br i1 %arg, label [[FOR_INC6]], label [[FOR_BODY_LR_PH:%.*]]
; CHECK:       for.body.lr.ph:
; CHECK-NEXT:    br label [[FOR_BODY4:%.*]]
; CHECK:       for.body4:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i32 [[PHIOFOPS]], [[Y_0]]
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_END:%.*]], label [[FOR_BODY4_1:%.*]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
; CHECK:       for.inc6:
; CHECK-NEXT:    [[INC7]] = add nuw nsw i32 [[Y_0]], 1
; CHECK-NEXT:    br label [[FOR_COND]]
; CHECK:       for.body4.1:
; CHECK-NEXT:    [[INC_1:%.*]] = add nuw nsw i32 [[Y_0]], 1
; CHECK-NEXT:    tail call void @use.i32(i32 [[INC_1]])
; CHECK-NEXT:    br label [[FOR_END]]
;
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc6, %entry
  %y.0 = phi i32 [ 1, %entry ], [ %inc7, %for.inc6 ]
  br i1 %arg, label %for.inc6, label %for.body.lr.ph

for.body.lr.ph:                                   ; preds = %for.cond
  %sub = add nsw i32 %y.0, -1
  br label %for.body4

for.body4:                                        ; preds = %for.body.lr.ph
  %cmp = icmp ugt i32 %sub, %y.0
  br i1 %cmp, label %for.end, label %for.body4.1

for.end:                                          ; preds = %for.body4.1, %for.body4
  ret void

for.inc6:                                         ; preds = %for.cond
  %inc7 = add nuw nsw i32 %y.0, 1
  br label %for.cond

for.body4.1:                                      ; preds = %for.body4
  %inc.1 = add nuw nsw i32 %y.0, 1
  tail call void @use.i32(i32 %inc.1)
  br label %for.end
}

define void @test2(i1 %c, ptr %ptr, i64 %N) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[HEADER:%.*]]
; CHECK:       header:
; CHECK-NEXT:    [[PHIOFOPS:%.*]] = phi i64 [ -1, [[ENTRY:%.*]] ], [ [[IV:%.*]], [[LATCH:%.*]] ]
; CHECK-NEXT:    [[IV]] = phi i64 [ [[IV_NEXT:%.*]], [[LATCH]] ], [ 0, [[ENTRY]] ]
; CHECK-NEXT:    br i1 [[C:%.*]], label [[IF_THEN:%.*]], label [[IF_ELSE:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[CMP1:%.*]] = icmp eq i64 [[IV]], 0
; CHECK-NEXT:    br i1 [[CMP1]], label [[LATCH]], label [[LOR_RHS:%.*]]
; CHECK:       lor.rhs:
; CHECK-NEXT:    [[IV_ADD_1:%.*]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[IDX_1:%.*]] = getelementptr inbounds i16, ptr [[PTR:%.*]], i64 [[IV_ADD_1]]
; CHECK-NEXT:    call void @use.i16(ptr [[IDX_1]])
; CHECK-NEXT:    ret void
; CHECK:       if.else:
; CHECK-NEXT:    [[IDX_2:%.*]] = getelementptr inbounds i16, ptr [[PTR]], i64 [[PHIOFOPS]]
; CHECK-NEXT:    call void @use.i16(ptr [[IDX_2]])
; CHECK-NEXT:    br label [[LATCH]]
; CHECK:       latch:
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[EC:%.*]] = icmp ugt i64 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[EC]], label [[HEADER]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %header

header:                                         ; preds = %for.inc, %entry
  %iv = phi i64 [ %iv.next, %latch ], [ 0, %entry ]
  br i1 %c, label %if.then, label %if.else

if.then:
  %cmp1 = icmp eq i64 %iv, 0
  br i1 %cmp1, label %latch, label %lor.rhs

lor.rhs:                                          ; preds = %if.then
  %iv.add.1 = add i64 %iv, 1
  %idx.1 = getelementptr inbounds i16, ptr %ptr, i64 %iv.add.1
  call void @use.i16(ptr %idx.1)
  ret void

if.else:
  %iv.sub.1 = add i64 %iv, -1
  %idx.2 = getelementptr inbounds i16, ptr %ptr, i64 %iv.sub.1
  call void @use.i16(ptr %idx.2)
  br label %latch

latch:
  %iv.next = add i64 %iv, 1
  %ec = icmp ugt i64 %iv.next, %N
  br i1 %ec, label %header, label %exit

exit:
  ret void
}

define void @pr49873_cmp_simplification_dependency(ptr %ptr, i1 %c.0) {
; CHECK-LABEL: @pr49873_cmp_simplification_dependency(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP_1:%.*]]
; CHECK:       loop.1:
; CHECK-NEXT:    br i1 [[C_0:%.*]], label [[LOOP_1_LATCH:%.*]], label [[LOOP_2:%.*]]
; CHECK:       loop.2:
; CHECK-NEXT:    [[I130:%.*]] = phi i32 [ [[I132:%.*]], [[LOOP_2]] ], [ 0, [[LOOP_1]] ]
; CHECK-NEXT:    [[I132]] = add nuw i32 [[I130]], 1
; CHECK-NEXT:    [[I133:%.*]] = load i32, ptr [[PTR:%.*]], align 4
; CHECK-NEXT:    [[C_1:%.*]] = icmp ult i32 [[I132]], [[I133]]
; CHECK-NEXT:    br i1 [[C_1]], label [[LOOP_2]], label [[LOOP_2_EXIT:%.*]]
; CHECK:       loop.2.exit:
; CHECK-NEXT:    br label [[LOOP_1_LATCH]]
; CHECK:       loop.1.latch:
; CHECK-NEXT:    [[DOTLCSSA:%.*]] = phi i32 [ 0, [[LOOP_1]] ], [ [[I133]], [[LOOP_2_EXIT]] ]
; CHECK-NEXT:    [[C_2:%.*]] = icmp ult i32 1, [[DOTLCSSA]]
; CHECK-NEXT:    br i1 [[C_2]], label [[LOOP_1]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop.1

loop.1:
  %i65 = add nuw i32 0, 1
  br i1 %c.0, label %loop.1.latch, label %loop.2

loop.2:
  %i130 = phi i32 [ %i132, %loop.2 ], [ 0, %loop.1 ]
  %i132 = add nuw i32 %i130, 1
  %i133 = load i32, ptr %ptr, align 4
  %c.1 = icmp ult i32 %i132, %i133
  br i1 %c.1, label %loop.2, label %loop.2.exit

loop.2.exit:
  br label %loop.1.latch

loop.1.latch:                                      ; preds = %loop.2.exit, %loop.1
  %.lcssa = phi i32 [ 0, %loop.1 ], [ %i133, %loop.2.exit ]
  %c.2 = icmp ult i32 %i65, %.lcssa
  br i1 %c.2, label %loop.1, label %exit

exit:
  ret void
}
