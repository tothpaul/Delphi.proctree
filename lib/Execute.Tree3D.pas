unit Execute.Tree3D;

{
  Delphi port of Javascript https://github.com/supereggbert/proctree.js (c)2011 Paul Brunt

  (c)2022 Execute SARL <https://www.execute.fr>

}

interface

uses
  System.Math;

type
  TVertex = packed record
    x, y, z: Single;
    constructor Create(x, y, z: Single);
  end;
  PVertex = ^TVertex;
  TVertices = TArray<TVertex>;
  TVerticesHelper = record helper for TVertices
    function push(const V: TVertex): Integer;
  end;

  TFace = packed record
    a, b, c: Integer;
  end;
  TFaces = TArray<TFace>;
  TFacesHelper = record helper for TFaces
    function push(a, b, c: Integer): Integer;
  end;

  TNormal = TVertex;
  TNormals = TVertices;
  TNormalsHelper = record helper for TNormals
    function push(const n: TNormal): Integer;
  end;

  TTexCoord = packed record
    u, v: Single;
    constructor Create(u, v: Single);
  end;
  TTexCoords = TArray<TTexCoord>;
  TTexCoordsHelper = record helper for TTexCoords
    function push(u, v: Single): Integer;
  end;

  TIntegers = TArray<Integer>;
  TIntegersHelper = record helper for TIntegers
    function push(const V: Integer): Integer;
  end;

  PBranch = ^TBranch;
  PTree = ^TTree;
  TBranch = record
    Parent: PBranch;
    child0: PBranch;
    child1: PBranch;
    head  : TVertex;
    length: Single;
    trunk : Boolean;
    radius: Single;
    root  : TIntegers;
    tangent: TVertex;
    ring0 : TIntegers;
    ring1 : TIntegers;
    ring2 : TIntegers;
    _end  : Integer;
    constructor create(const head: TVertex; parent: PBranch = nil);
    procedure split(level, steps: Integer; Tree: PTree; l1: Integer = 1; l2: Integer = 1);
    function mirrorBranch(const vec, norm: TVertex; Tree: PTree): TVertex;
    class operator initialize(out Branch: TBranch);
    class operator finalize(var Branch: TBranch);
  end;

  TTree = record
  private
    rseed: Integer;
    root: TBranch;
    function random(a: Integer = 0): Single;
    procedure calcNormals;
    procedure doFaces(branch: PBranch);
    procedure createForks(branch: PBranch; radius: Single);
    procedure createTwigs(branch: PBranch);
  public
  // params
    seed: Integer;
    segments: Integer;
    levels: Integer;
    vMultiplier: Single;
    twigScale: Single;
    initialBranchLength: Single;
    lengthFalloffFactor: Single;
    lengthFalloffPower: Single;
    clumpMax: Single;
    clumpMin: Single;
    branchFactor: Single;
    dropAmount: Single;
    growAmount: Single;
    sweepAmount: Single;
    maxRadius: Single;
    climbRate: Single;
    trunkKink: Single;
    treeSteps: Integer;
    taperRate: Single;
    radiusFalloffRate: Single;
    twistRate: Single;
    trunkLength: Single;

  // result

    verts: TVertices;
    Normals: TArray<TNormal>;
    faces: TArray<TFace>;
    UV: TArray<TTexCoord>;

    vertsTwig: TVertices;
    normalsTwig: TNormals;
    facesTwig: TFaces;
    uvsTwig: TTexCoords;

    class operator Initialize(out Tree: TTree);
    procedure Default;
    procedure Demo1;
    procedure Preset1;
    procedure Preset2;
    procedure Preset3;
    procedure Preset4;
    procedure Preset5;
    procedure Preset6;
    procedure Preset7;
    procedure Preset8;
    procedure Build;
    procedure Clear;
  end;

implementation

const
  DOWN_VECTOR: TVertex = (x: -1; y: 0; z: 0);

function scaleVec(const v: TVertex; s: Single): TVertex;
begin
  Result.x := v.x * s;
  Result.y := v.y * s;
  Result.z := v.z * s;
end;

function vLength(const v: TVertex): Single;
begin
  Result := sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
end;

function normalize(const v: TVertex): TVertex;
begin
  var l := vLength(v);
  Result := scaleVec(v, 1/l);
end;

function dot(const v1, v2: TVertex): Single;
begin
  Result := v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
end;

function cross(const v1, v2: TVertex): TVertex;
begin
  Result.x := v1.y * v2.z - v1.z * v2.y;
  Result.y := v1.z * v2.x - v1.x * v2.z;
  Result.z := v1.x * v2.y - v1.y * v2.x;
end;

function addVec(const v1, v2: TVertex): TVertex;
begin
  Result.x := v1.x + v2.x;
  Result.y := v1.y + v2.y;
  Result.z := v1.z + v2.z;
end;

function subVec(const v1, v2: TVertex): TVertex;
begin
  Result.x := v1.x - v2.x;
  Result.y := v1.y - v2.y;
  Result.z := v1.z - v2.z;
end;

function vecAxisAngle(const vec, axis: TVertex; angle: Single): TVertex;
begin
  var cosr := cos(angle);
  var sinr := sin(angle);
  Result := addVec(addVec(scaleVec(vec, cosr), scaleVec(cross(axis, vec), sinr)), scaleVec(axis, dot(axis, vec) * (1 - cosr)));
end;

function scaleInDirection(const vector, direction: TVertex; scale: Single): TVertex;
begin
  var currentMag := dot(vector, direction);

  var change := scaleVec(direction, currentMag * scale - currentMag);
  Result := addVec(vector, change);
end;

function newBranch(const head: TVertex; const parent: TBranch): PBranch;
begin
  New(Result);
  Result.head := head;
  Result.Parent := @parent;
end;

procedure freeBranch(var branch: PBranch);
begin
  if branch <> nil then
  begin
    dispose(branch);
    branch := nil;
  end;
end;

{ TTree }

procedure TTree.Build;
begin
  rseed := seed;

// initial branch
  root.Create(TVertex.Create(0, trunkLength, 0));
  root.length := initialBranchLength;

  Clear;

// Y
  root.split(levels, treeSteps, @Self);

  createForks(@root, maxRadius);
  createTwigs(@root);

  doFaces(@root);
  calcNormals();
end;

procedure TTree.Clear;
begin
  verts := nil;
  faces := nil;
  normals := nil;
  UV := nil;

  vertsTwig := nil;
  facesTwig := nil;
  uvsTwig := nil;
  normalsTwig := nil;

  FreeBranch(root.child0);
  FreeBranch(root.child1);
end;

procedure TTree.Demo1;
begin
  seed := 262;
  segments := 6;
  levels := 5;
  vMultiplier := 2.36;
  twigScale := 0.39;
  initialBranchLength := 0.49;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.99;
  clumpMax := 0.454;
  clumpMin := 0.404;
  branchFactor := 2.45;
  dropAmount := 0.01;
  growAmount := 0.235;
  sweepAmount := 0.01;
  maxRadius := 0.139;
  climbRate := 0.371;
  trunkKink := 0.093;
  treeSteps := 5;
  taperRate := 0.947;
  radiusFalloffRate := 0.73;
  twistRate := 3.02;
  trunkLength := 2.4;
  Build;
end;

procedure TTree.doFaces(branch: PBranch);
begin
  if branch.Parent = nil then
  begin
    SetLength(UV, Length(verts));
    var tangent := normalize(cross(subVec(branch.child0.head, branch.head), subVec(branch.child1.head, branch.head)));
    var normal := normalize(branch.head);
    var angle := ArcCos(dot(tangent, DOWN_VECTOR));
    if dot(cross(DOWN_VECTOR, tangent), normal) > 0 then angle := 2 * PI - angle;
    var segOffset := round(angle/PI/2*segments);
    for var i := 0 to segments - 1 do
    begin
      var v1 := branch.ring0[i];
      var v2 := branch.root[(i + segOffset + 1) mod segments];
      var v3 := branch.root[(i + segOffset ) mod segments];
      var v4 := branch.ring0[(i + 1) mod segments];
      faces.push(v1, v4, v3);
      faces.push(v4, v2, v3);
      UV[(i + segOffset) mod segments] := TTexCoord.Create(Abs(i/segments - 0.5) * 2, 0);
      var len := vlength(subVec(verts[branch.ring0[i]], verts[branch.root[(i + segOffset) mod segments]])) * vMultiplier;
      UV[branch.ring0[i]] := TTexCoord.Create(Abs(i/segments - 0.5) * 2, len);
      UV[branch.ring2[i]] := TTexCoord.Create(Abs(i/segments - 0.5) * 2, len);
    end;
  end;

  if Length(branch.child0.ring0) > 0 then
  begin
    var segOffset0, segOffset1: Integer;
    var match0, match1: Single;

    var v1 := normalize(subVec(verts[branch.ring1[0]], branch.head));
    var v2 := normalize(subVec(verts[branch.ring2[0]], branch.head));

    v1 := scaleInDirection(v1, normalize(subVec(branch.child0.head, branch.head)), 0);
    v2 := scaleInDirection(v2, normalize(subVec(branch.child1.head, branch.head)), 0);

    for var i := 0 to segments - 1 do
    begin
      var d := normalize(subVec(verts[branch.child0.ring0[i]], branch.child0.head));
      var l := dot(d, v1);
      if (i = 0) or (l > match0) then
      begin
        match0 := l;
        segOffset0 := segments - i;
      end;
      d := normalize(subVec(verts[branch.child1.ring0[i]], branch.child1.head));
      l := dot(d, v2);
      if (i = 0) or (l > match1) then
      begin
        match1 := l;
        segOffset1 := segments - i;
      end;

    end;

    var UVScale := maxRadius/branch.radius;

    for var i := 0 to segments - 1 do
    begin
      var f1 := branch.child0.ring0[i];
      var f2 := branch.ring1[(i+segOffset0+1) mod segments];
      var f3 := branch.ring1[(i+segOffset0) mod segments];
      var f4 := branch.child0.ring0[(i + 1) mod segments];
      faces.push(f1, f4, f3);
      faces.push(f4, f2, f3);
      f1 := branch.child1.ring0[i];
      f2 := branch.ring2[(i+segOffset1+1) mod segments];
      f3 := branch.ring2[(i+segOffset1) mod segments];
      f4 := branch.child1.ring0[(i+1) mod segments];
      faces.push(f1, f2, f3);
      faces.push(f1, f4, f2);

      var len1 := vlength(subVec(verts[branch.child0.ring0[i]], verts[branch.ring1[(i+segOffset0) mod segments]])) * UVScale;
      var uv1 := UV[branch.ring1[(i+segOffset0-1) mod segments]];

      UV[branch.child0.ring0[i]] := TTexCoord.Create(uv1.u, uv1.v + len1 * vMultiplier);
      UV[branch.child0.ring2[i]] := TTexCoord.Create(uv1.u, uv1.v + len1 * vMultiplier);

      var len2 := vlength(subVec(verts[branch.child1.ring0[i]], verts[branch.ring2[(i+segOffset1) mod segments]])) * UVScale;
      var uv2 := UV[branch.ring2[(i+segOffset1-1) mod segments]];

      UV[branch.child1.ring0[i]] := TTexCoord.Create(uv2.u, uv2.v + len2 * vMultiplier);
      UV[branch.child1.ring2[i]] := TTexCoord.Create(uv2.u, uv2.v + len2 * vMultiplier);
    end;

    doFaces(branch.child0);
		doFaces(branch.child1);
  end else begin
    for var i :=0 to  segments - 1 do
    begin
      faces.push(branch.child0._end, branch.ring1[(i+1) mod segments],branch.ring1[i]);
      faces.push(branch.child1._end, branch.ring2[(i+1) mod segments],branch.ring2[i]);


      var len := vlength(subVec(verts[branch.child0._end], verts[branch.ring1[i]]));
      UV[branch.child0._end] := TTexCoord.Create(abs(i/segments - 1 - 0.5) * 2,len * vMultiplier);
      len := vlength(subVec(verts[branch.child1._end], verts[branch.ring2[i]]));
      UV[branch.child1._end] := TTexCoord.Create(abs(i/segments - 0.5) * 2, len * vMultiplier);
    end;
  end;

end;

class operator TTree.Initialize(out Tree: TTree);
begin
  Tree.Default;
end;

procedure TTree.Preset1;
begin
  seed := 262;
  segments := 6;
  levels := 5;
  vMultiplier := 2.36;
  twigScale := 0.39;
  initialBranchLength := 0.49;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.99;
  clumpMax := 0.454;
  clumpMin := 0.404;
  branchFactor := 2.45;
  dropAmount := -0.1;
  growAmount := 0.235;
  sweepAmount := 0.01;
  maxRadius := 0.139;
  climbRate := 0.371;
  trunkKink := 0.093;
  treeSteps := 5;
  taperRate := 0.947;
  radiusFalloffRate := 0.73;
  twistRate := 3.02;
  trunkLength := 2.4;
//  trunkMaterial := TrunkType1;
//  twigMaterial := BranchType6;
end;

procedure TTree.Preset2;
begin
  seed := 861;
  segments := 10;
  levels := 5;
  vMultiplier := 0.66;
  twigScale := 0.47;
  initialBranchLength := 0.5;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.99;
  clumpMax := 0.449;
  clumpMin := 0.404;
  branchFactor := 2.75;
  dropAmount := 0.07;
  growAmount := -0.005;
  sweepAmount := 0.01;
  maxRadius := 0.269;
  climbRate := 0.626;
  trunkKink := 0.108;
  treeSteps := 4;
  taperRate := 0.876;
  radiusFalloffRate := 0.66;
  twistRate := 2.7;
  trunkLength := 1.55;
//  trunkMaterial := TrunkType2;
//  twigMaterial := BranchType5;
end;

procedure TTree.Preset3;
begin
  seed := 152;
  segments := 6;
  levels := 5;
  vMultiplier := 1.16;
  twigScale := 0.44;
  initialBranchLength := 0.49;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.99;
  clumpMax := 0.454;
  clumpMin := 0.246;
  branchFactor := 3.2;
  dropAmount := 0.09;
  growAmount := 0.235;
  sweepAmount := 0.01;
  maxRadius := 0.111;
  climbRate := 0.41;
  trunkKink := 0;
  treeSteps := 5;
  taperRate := 0.835;
  radiusFalloffRate := 0.73;
  twistRate := 2.06;
  trunkLength := 2.45;
//trunkMaterial := TrunkType3;
//twigMaterial := BranchType2;
end;

procedure TTree.Preset4;
begin
  seed := 499;
  segments := 8;
  levels := 5;
  vMultiplier := 1;
  twigScale := 0.28;
  initialBranchLength := 0.5;
  lengthFalloffFactor := 0.98;
  lengthFalloffPower := 1.08;
  clumpMax := 0.414;
  clumpMin := 0.282;
  branchFactor := 2.2;
  dropAmount := 0.24;
  growAmount := 0.044;
  sweepAmount := 0;
  maxRadius := 0.096;
  climbRate := 0.39;
  trunkKink := 0;
  treeSteps := 5;
  taperRate := 0.958;
  radiusFalloffRate := 0.71;
  twistRate := 2.97;
  trunkLength := 1.95;
//  trunkMaterial := TrunkType3;
//  twigMaterial := BranchType3;
end;

procedure TTree.Preset5;
begin
  seed := 267;
  segments := 8;
  levels := 4;
  vMultiplier := 0.96;
  twigScale := 0.71;
  initialBranchLength := 0.12;
  lengthFalloffFactor := 1;
  lengthFalloffPower := 0.7;
  clumpMax := 0.556;
  clumpMin := 0.404;
  branchFactor := 3.5;
  dropAmount := 0.18;
  growAmount := -0.108;
  sweepAmount := 0.01;
  maxRadius := 0.139;
  climbRate := 0.419;
  trunkKink := 0.093;
  treeSteps := 5;
  taperRate := 0.947;
  radiusFalloffRate := 0.73;
  twistRate := 3.53;
  trunkLength := 1.75;
//  trunkMaterial := TrunkType3;
//  twigMaterial := BranchType4;
end;

procedure TTree.Preset6;
begin
  seed := 519;
  segments := 6;
  levels := 5;
  vMultiplier := 1.01;
  twigScale := 0.52;
  initialBranchLength := 0.65;
  lengthFalloffFactor := 0.73;
  lengthFalloffPower := 0.76;
  clumpMax := 0.53;
  clumpMin := 0.419;
  branchFactor := 3.4;
  dropAmount := -0.16;
  growAmount := 0.128;
  sweepAmount := 0.01;
  maxRadius := 0.168;
  climbRate := 0.472;
  trunkKink := 0.06;
  treeSteps := 5;
  taperRate := 0.835;
  radiusFalloffRate := 0.73;
  twistRate := 1.29;
  trunkLength := 2.2;
//  trunkMaterial := TrunkType2;
//  twigMaterial := BranchType1;
end;

procedure TTree.Preset7;
begin
  seed := 152;
  segments := 8;
  levels := 5;
  vMultiplier := 1.16;
  twigScale := 0.39;
  initialBranchLength := 0.49;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.99;
  clumpMax := 0.454;
  clumpMin := 0.454;
  branchFactor := 3.2;
  dropAmount := 0.09;
  growAmount := 0.235;
  sweepAmount := 0.051;
  maxRadius := 0.105;
  climbRate := 0.322;
  trunkKink := 0;
  treeSteps := 5;
  taperRate := 0.964;
  radiusFalloffRate := 0.73;
  twistRate := 1.5;
  trunkLength := 2.25;
//  trunkMaterial := TrunkType1;
//  twigMaterial := BranchType2;
end;

procedure TTree.Preset8;
begin
  seed := 267;
  segments := 8;
  levels := 4;
  vMultiplier := 0.96;
  twigScale := 0.7;
  initialBranchLength := 0.26;
  lengthFalloffFactor := 0.94;
  lengthFalloffPower := 0.7;
  clumpMax := 0.556;
  clumpMin := 0.404;
  branchFactor := 3.5;
  dropAmount := -0.15;
  growAmount := 0.28;
  sweepAmount := 0.01;
  maxRadius := 0.139;
  climbRate := 0.419;
  trunkKink := 0.093;
  treeSteps := 5;
  taperRate := 0.947;
  radiusFalloffRate := 0.73;
  twistRate := 3.32;
  trunkLength := 2.2;
//  trunkMaterial := TrunkType1;
//  twigMaterial := BranchType3;
end;

function TTree.random(a: Integer): Single;
begin
  if a = 0 then
  begin
    Inc(rseed);
    a := rseed;
  end;
  Result := Abs(cos(a + a * a));
end;

procedure TTree.calcNormals;
begin
  var allNormals: TArray<TNormals>;
  var vCount := Length(verts);
  SetLength(allNormals, vCount);
  for var i := 0 to Length(faces) - 1 do
  begin
    with faces[i] do
    begin
      var norm := normalize(cross(subVec(verts[a], verts[b]), subVec(verts[a], verts[c])));
      allNormals[a].push(norm);
      allNormals[b].push(norm);
      allNormals[c].push(norm);
    end;
  end;
  SetLength(normals, vCount);
  for var i := 0 to vCount - 1 do
  begin
    var total := TVertex.Create(0, 0, 0);
    var l := Length(allNormals[i]);
    for var J := 0 to l - 1 do
      total := addVec(total, allNormals[i, j]);
     normals[i] := normalize(total);
  end;

end;

procedure TTree.createForks(branch: PBranch; radius: Single);
begin
  branch.radius := radius;

  if radius > branch.length then
    radius := branch.length;

  var segmentAngle := PI * 2 / segments;

  var axis: TVertex;

  if branch.Parent = nil then
  begin
    // create the root of the tree
    branch.root := nil;
    axis := TVertex.Create(0, 1, 0);
    for var i := 0 to segments - 1 do
    begin
      var vec := vecAxisAngle(DOWN_VECTOR, axis, -segmentAngle * i);
      branch.root.push(Length(verts));
      verts.push(scaleVec(vec, radius / radiusFalloffRate));
    end;
  end;

  // cross the branches to get the left
  // add the branches to get the up
  if branch.child0 <> nil then
  begin
    if branch.Parent <> nil then
      axis := normalize(subVec(branch.head, branch.Parent.head))
    else
      axis := normalize(branch.head);

    var axis1 := normalize(subVec(branch.head, branch.child0.head));
    var axis2 := normalize(subVec(branch.head, branch.child1.head));
    var tangent := normalize(cross(axis1, axis2));
    branch.tangent := tangent;

    var axis3 := normalize(cross(tangent, normalize(addVec(scaleVec(axis1, -1), scaleVec(axis2, -1)))));
    var dir := TVertex.Create(axis2.x, 0, axis2.z);
    var centerloc := addVec(branch.head, scaleVec(dir, -maxRadius/2));

    var scale := radiusFalloffRate;

    branch.ring0 := nil;
    branch.ring1 := nil;
    branch.ring2 := nil;

    if (branch.child0.trunk) or (branch.trunk) then
      scale := 1/taperRate;

    // main segment ring
    var linch0 := length(verts);
    branch.ring0.push(linch0);
    branch.ring2.push(linch0);
    verts.push(addVec(centerloc, scaleVec(tangent, radius * scale)));

    var start := linch0;
    var d1 := vecAxisAngle(tangent, axis2, 1.57);
    var d2 := normalize(cross(tangent, axis));
    var s := 1/dot(d1, d2);
    for var i := 1 to segments div 2 - 1 do
    begin
      var vec := vecAxisAngle(tangent, axis2, segmentAngle * i);
      branch.ring0.push(start + i);
      branch.ring2.push(start + i);
      vec := scaleInDirection(vec, d2, s);
      verts.push(addVec(centerloc, scaleVec(vec, radius * scale)));
    end;
    var linch1 := Length(verts);
    branch.ring0.push(linch1);
    branch.ring1.push(linch1);
    verts.push(addVec(centerloc, scaleVec(tangent, -radius * scale)));
    for var i := segments div 2 + 1 to segments - 1 do
    begin
      var vec := vecAxisAngle(tangent, axis1, segmentAngle * i);
      branch.ring0.push(Length(verts));
      branch.ring1.push(Length(verts));
      verts.push(addVec(centerloc, scaleVec(vec, radius * scale)));
    end;
    branch.ring1.push(linch0);
    branch.ring2.push(linch1);
    start := length(verts) - 1;
    for var i := 1 to segments div 2 - 1 do
    begin
      var vec := vecAxisAngle(tangent, axis3, segmentAngle * i);
      branch.ring1.push(start + i);
      branch.ring2.push(start + (segments div 2 - i));
      var v := scaleVec(vec, radius * scale);
      verts.push(addVec(centerloc, v));
    end;

    // child radius is related to the branch direction and the length of the branch
    var length0 := vlength(subVec(branch.head, branch.child0.head));
    var length1 := vlength(subVec(branch.head, branch.child1.head));

    var radius0 := 1 * radius * radiusFalloffRate;
    var radius1 := 1 * radius * radiusFalloffRate;
    if branch.child0.trunk then
      radius0 := radius * taperRate;
    createForks(branch.child0, radius0);
    createForks(branch.child1, radius1);
  end else begin
    // add points for the ends of branches
    branch._end := length(verts);
    verts.push(branch.head);
  end;
end;

procedure TTree.createTwigs(branch: PBranch);
begin
  if branch.child0 = nil then
  begin
    var tangent := normalize(cross(subVec(branch.Parent.child0.head, branch.Parent.head), subVec(branch.Parent.child1.head, branch.parent.head)));
    var binormal := normalize(subVec(branch.head, branch.Parent.head));
    var normal := cross(tangent, binormal);

    var vert1 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent, twigScale)), scaleVec(binormal, twigScale * 2 - branch.length)));
    var vert2 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent,-twigScale)), scaleVec(binormal, twigScale * 2 - branch.length)));
    var vert3 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent,-twigScale)), scaleVec(binormal, -branch.length)));
    var vert4 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent, twigScale)), scaleVec(binormal, -branch.length)));

    var vert8 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent, twigScale)), scaleVec(binormal, twigScale * 2 - branch.length)));
    var vert7 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent,-twigScale)), scaleVec(binormal, twigScale * 2 - branch.length)));
    var vert6 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent,-twigScale)), scaleVec(binormal, -branch.length)));
    var vert5 := length(vertsTwig);
    vertsTwig.push(addVec(addVec(branch.head, scaleVec(tangent, twigScale)), scaleVec(binormal, -branch.length)));

    facesTwig.push(vert1, vert2, vert3);
    facesTwig.push(vert4, vert1, vert3);

    facesTwig.push(vert6, vert7, vert8);
    facesTwig.push(vert6, vert8, vert5);

    normal := normalize(cross(subVec(vertsTwig[vert1],vertsTwig[vert3]),subVec(vertsTwig[vert2],vertsTwig[vert3])));
    var normal2 := normalize(cross(subVec(vertsTwig[vert7],vertsTwig[vert6]),subVec(vertsTwig[vert8],vertsTwig[vert6])));

    normalsTwig.push(normal);
    normalsTwig.push(normal);
    normalsTwig.push(normal);
    normalsTwig.push(normal);

    normalsTwig.push(normal2);
    normalsTwig.push(normal2);
    normalsTwig.push(normal2);
    normalsTwig.push(normal2);

    uvsTwig.push(0, 0);
    uvsTwig.push(1, 0);
    uvsTwig.push(1, 1);
    uvsTwig.push(0, 1);

    uvsTwig.push(0, 0);
    uvsTwig.push(1, 0);
    uvsTwig.push(1, 1);
    uvsTwig.push(0, 1);
  end else begin
    createTwigs(branch.child0);
    createTwigs(branch.child1);
  end;
end;

procedure TTree.Default;
begin
  FillChar(Self, SizeOf(Self), 0);
  clumpMax := 0.8;
  clumpMin := 0.5;
  lengthFalloffFactor := 0.85;
  lengthFalloffPower := 0.6;
  branchFactor := 2.0;
  radiusFalloffRate := 0.6;
  climbRate := 1.5;
//  trunkKink := 0.0;
  maxRadius := 0.25;
  treeSteps := 2;
  taperRate := 0.95;
  twistRate := 13;
  segments := 6;
  levels := 3;
//  sweepAmount := 0;
  initialBranchLength := 0.85;
  trunkLength := 2.5;
//  dropAmount := 0.0;
//  growAmount := 0.0;
  vMultiplier := 0.2;
  twigScale := 2.0;
  seed := 10;
end;

{ TBranch }

constructor TBranch.create(const head: TVertex; parent: PBranch = nil);
begin
  Self.head := head;
  Self.Parent := parent;
end;

class operator TBranch.finalize(var Branch: TBranch);
begin
  if Branch.child0 <> nil then
    Dispose(Branch.child0);
  if Branch.child1 <> nil then
    Dispose(Branch.child1);
end;

class operator TBranch.initialize(out Branch: TBranch);
begin
  FillChar(Branch, SizeOf(Branch), 0);
end;

function TBranch.mirrorBranch(const vec, norm: TVertex; Tree: PTree): TVertex;
begin
  var v := cross(norm, cross(vec, norm));
  var s := tree.branchFactor * dot(v, vec);
  Result := TVertex.Create(vec.x - v.x * s, vec.y - v.y * s, vec.z - v.z * s);
end;

procedure TBranch.split(level, steps: Integer; Tree: PTree; l1: Integer = 1; l2: Integer = 1);
begin
  var rLevel := Tree.levels - level;

  // branch origine
  var po: TVertex;

  if parent <> nil then
    po := parent.head
  else begin
    FillChar(po, SizeOf(po), 0);
    trunk := True;
  end;

  var so := head;
  // direction of the branch
  var dir := normalize(subVec(so, po));

  var normal := cross(dir, TVertex.Create(dir.z, dir.x, dir.y));
  var tangent := cross(dir, normal);

  var r := Tree.random(rLevel * 10 + l1 * 5 + l2 + Tree.seed);
  var r2 := Tree.random(rLevel * 10 + l1 * 5 + l2 + 1 + Tree.seed);

  var clumpmax := Tree.clumpMax;
  var clumpmin := Tree.clumpMin;

  var adj := addVec(scaleVec(normal, r), scaleVec(tangent, 1 - r));
  if r > 0.5 then
    adj := scaleVec(adj, -1);

  var clump := (clumpmax -clumpmin) * r + clumpmin;
  var newdir := normalize(addVec(scaleVec(adj, 1 - clump), scaleVec(dir, clump)));

  var newdir2 := mirrorBranch(newdir, dir, Tree);
  if r > 0.5 then
  begin
    var tmp := newdir;
    newdir := newdir2;
    newdir2 := tmp;
  end;
  if steps > 0 then
  begin
    var angle := steps/tree.treeSteps * 2 * PI * tree.twistRate;
    newdir2 := normalize(TVertex.Create(sin(Angle), r, cos(angle)));
  end;

  var growAmount := level * level / (tree.levels * tree.levels) * tree.growAmount;
  var dropAmount := rLevel * tree.dropAmount;
  var sweepAmount := rLevel * tree.sweepAmount;
  var tmpVec := TVertex.Create(sweepAmount, dropAmount + growAmount, 0);
  newdir := normalize(addVec(newdir, tmpVec));
  newdir2 := normalize(addVec(newdir2, tmpVec));

  var head0 := addVec(so, scaleVec(newdir, length));
  var head1 := addVec(so, scaleVec(newdir2, length));
  child0 := newBranch(head0, Self);
  child1 := newBranch(head1, Self);
  child0.length := Power(length, tree.lengthFalloffPower) * tree.lengthFalloffFactor;
  child1.length := child0.length;
  if level > 0 then
  begin
    if steps > 0 then
    begin
      child0.head := addVec(head, TVertex.Create((r - 0.5) * 2 * tree.trunkKink, tree.climbRate, (r - 0.5) * 2 * tree.trunkKink));
      child0.trunk := True;
      child0.length := length * tree.taperRate;
      child0.split(level, steps - 1, Tree, l1 + 1, l2);
    end else begin
      child0.split(level - 1, 0, tree, l1 + 1, l2);
    end;
    child1.split(level - 1, 0, Tree, l1, l2 + 1);
  end;
end;

{ TVertex }

constructor TVertex.Create(x, y, z: Single);
begin
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

{ TIntegersHelper }

// NB: push() functions are inefficient but close to the original source code
// we should determine the total amount of items and allocate the buffer at once

function TIntegersHelper.push(const V: Integer): Integer;
begin
  Result := Length(Self);
  SetLength(Self, Result + 1);
  Self[Result] := V;
end;

{ TVerticesHelper }

function TVerticesHelper.push(const V: TVertex): Integer;
begin
  Result := Length(Self);
  SetLength(Self, Result + 1);
  Self[Result] := V;
end;

{ TFacesHelper }

function TFacesHelper.push(a, b, c: Integer): Integer;
begin
  Result := Length(Self);
  SetLength(Self, Result + 1);
  Self[Result].a := a;
  Self[Result].b := b;
  Self[Result].c := c;
end;

{ TTexCoordsHelper }

function TTexCoordsHelper.push(u, v: Single): Integer;
begin
  Result := Length(Self);
  SetLength(Self, Result + 1);
  Self[Result].u := u;
  Self[Result].v := v;
end;

{ TNormalsHelper }

function TNormalsHelper.push(const n: TNormal): Integer;
begin
  Result := Length(Self);
  SetLength(Self, Result + 1);
  Self[Result] := n;
end;

{ TTexCoord }

constructor TTexCoord.Create(u, v: Single);
begin
  Self.u := u;
  Self.v := v;
end;

end.
