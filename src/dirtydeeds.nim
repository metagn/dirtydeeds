import macros

proc extractParam(node, defaultType: NimNode, count: int): NimNode =
  result = nil
  case node.kind
  of nnkCallKinds, nnkObjConstr:
    # _(a) means param named a
    if node.len == 2 and node[0].kind == nnkIdent and node[0].eqIdent"_":
      result = newIdentDefs(node[1], defaultType)
      result.copyLineInfo(node)
  of nnkExprEqExpr, nnkAsgn:
    # default value
    result = extractParam(node[0], defaultType, count)
    if not result.isNil:
      result[2] = node[1]
  of nnkExprColonExpr:
    # type
    result = extractParam(node[0], defaultType, count)
    if not result.isNil:
      result[1] = node[1]
  of nnkIdent:
    if node.eqIdent"_":
      result = newIdentDefs(ident("_" & $count), defaultType)
      result.copyLineInfo(node)
  of nnkPar, nnkTupleConstr:
    if node.len == 1 and node[0].kind notin {nnkPar, nnkTupleConstr}:
      result = extractParam(node[0], defaultType, count)
  else: discard

proc impl(node: NimNode): NimNode =
  const
    paramPos = 3
    genericPos = 2
    bodyPos = ^1
  if node.kind in RoutineNodes:
    result = node
  else:
    result = newProc(
      procType = nnkLambda,
      body = node)
    result.copyLineInfo(node)
  let defaultType =
    if result.kind in {nnkTemplateDef, nnkMacroDef}:
      ident"untyped"
    else:
      ident"auto"
  if result[paramPos][0].kind == nnkEmpty:
    result[paramPos][0] = defaultType
  var paramCount = 0
  if result[bodyPos].kind in {nnkStmtList, nnkStmtListExpr}:
    var i = 0
    while i < result[bodyPos].len - 1:
      let e = result[bodyPos][i]
      let p = extractParam(e, defaultType, paramCount)
      if not p.isNil:
        result[paramPos].add(p)
        inc paramCount
        result[bodyPos].del(i)
      else:
        inc i
  else:
    let old = result[bodyPos]
    result[bodyPos] = newNimNode(nnkStmtListExpr, old)
    result[bodyPos].add(old)
  let
    body = result[bodyPos]
    callPos = body.len - 1
  let call = body[callPos]
  case call.kind
  of nnkCallKinds, nnkObjConstr, nnkBracketExpr, nnkCurlyExpr,
      nnkPar, nnkTupleConstr, nnkBracket, nnkCurly:
    if call.kind in nnkCallKinds + {nnkObjConstr}:
      let callee = call[0]
      if callee.kind == nnkBracketExpr:
        # maybe generic params
        var genericParams: seq[NimNode]
        var i = 1
        while i < callee.len:
          let p = extractParam(callee[i], newEmptyNode(), paramCount)
          if not p.isNil:
            genericParams.add(p)
            inc paramCount
            callee.del(i)
          else:
            inc i
        if genericParams.len != 0:
          if result[genericPos].kind == nnkEmpty:
            result[genericPos] = newNimNode(nnkGenericParams, callee)
          result[genericPos].add(genericParams)
          if callee.len == 1:
            call[0] = callee[0]
    for i in 0 ..< call.len:
      let p = extractParam(call[i], defaultType, paramCount)
      if not p.isNil:
        result[paramPos].add(p)
        inc paramCount
        call[i] = p[0]
    if call.kind == nnkObjConstr and
        call.len > 1 and call[1].kind != nnkExprColonExpr:
      body[callPos] = newNimNode(nnkCall, call)
      for a in call: body[callPos].add(a)
  of nnkDotExpr, nnkDerefExpr:
    let p = extractParam(call[0], defaultType, paramCount)
    if not p.isNil:
      result[paramPos].add(p)
      inc paramCount
      call[0] = p[0]
  else:
    warning("unsupported deed node kind " & $body[callPos].kind, body[callPos])

macro deed*(node): untyped =
  result = impl(node)
