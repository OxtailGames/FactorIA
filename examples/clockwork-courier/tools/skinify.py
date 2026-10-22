"""Turn a glTF whose rigid meshes hang under bone nodes into a properly skinned one (every vertex 100% on its bone).
Usage: python3 skinify.py in.glb out.glb. Used for robot.glb and pets/animal-dog.glb (see ENGINE_FEEDBACK FB-0001)."""
import json, struct, math, sys
P = sys.argv[1]
b = open(P, 'rb').read()
l = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + l])
rest = b[20 + l:]
bl = struct.unpack('<I', rest[0:4])[0]
bin_ = bytearray(rest[8:8 + bl])

def ident():
    return [[1.0 if r == c else 0.0 for c in range(4)] for r in range(4)]
def mul(a, b_):
    return [[sum(a[r][k] * b_[k][c] for k in range(4)) for c in range(4)] for r in range(4)]
def trs(n):
    t = n.get('translation', [0, 0, 0]); q = n.get('rotation', [0, 0, 0, 1]); s = n.get('scale', [1, 1, 1])
    x, y, z, w = q
    r = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    m = ident()
    for i in range(3):
        for k in range(3):
            m[i][k] = r[i][k] * s[k]
        m[i][3] = t[i]
    return m
def inv(m):
    a = [row[:] + [1.0 if i == k else 0.0 for k in range(4)] for i, row in enumerate(m)]
    for c in range(4):
        p = max(range(c, 4), key=lambda r: abs(a[r][c]))
        a[c], a[p] = a[p], a[c]
        d = a[c][c]
        a[c] = [v / d for v in a[c]]
        for r in range(4):
            if r != c:
                f = a[r][c]
                a[r] = [v - f * w for v, w in zip(a[r], a[c])]
    return [row[4:] for row in a]

nodes = j['nodes']
parent = {}
for i, n in enumerate(nodes):
    for c in n.get('children', []):
        parent[c] = i
gl = {}
def glob(i):
    if i not in gl:
        m = trs(nodes[i])
        gl[i] = mul(glob(parent[i]), m) if i in parent else m
    return gl[i]

# joints = the nodes the animation channels target (bones) plus their ancestors below the scene root are not needed
chan_nodes = set()
for a in j['animations']:
    for ch in a['channels']:
        chan_nodes.add(ch['target']['node'])
bone_nodes = sorted(chan_nodes)
# include every node that is an ancestor of a mesh node and below the armature (so the chain is complete)
mesh_nodes = [i for i, n in enumerate(nodes) if 'mesh' in n]
joint_set = set(bone_nodes)
for mi in mesh_nodes:
    k = mi
    while k in parent:
        k = parent[k]
        if nodes[k].get('name') == 'RobotArmature':
            break
        joint_set.add(k)
# drop nodes that are mesh nodes themselves from joints
# (a mesh node that is itself animated, like the legs of Kenney's cube pets, is its own bone)
for mi in mesh_nodes:
    if mi not in chan_nodes:
        joint_set.discard(mi)
for i in list(joint_set):
    if nodes[i].get('name') in ('RootNode', 'RobotArmature'):
        joint_set.discard(i)
joints = sorted(joint_set)
jindex = {n: i for i, n in enumerate(joints)}
print('joints', len(joints))

def pad():
    while len(bin_) % 4:
        bin_.append(0)
def add_view(data, target=None):
    pad()
    off = len(bin_)
    bin_.extend(data)
    v = {'buffer': 0, 'byteOffset': off, 'byteLength': len(data)}
    if target:
        v['target'] = target
    j['bufferViews'].append(v)
    return len(j['bufferViews']) - 1
def add_acc(view, ctype, count, typ, **kw):
    a = {'bufferView': view, 'componentType': ctype, 'count': count, 'type': typ}
    a.update(kw)
    j['accessors'].append(a)
    return len(j['accessors']) - 1
def read_vec3(ai):
    a = j['accessors'][ai]; v = j['bufferViews'][a['bufferView']]
    off = v.get('byteOffset', 0) + a.get('byteOffset', 0); st = v.get('byteStride', 12)
    return [struct.unpack_from('<3f', bin_, off + k * st) for k in range(a['count'])]

used_meshes = {}
for mi in mesh_nodes:
    n = nodes[mi]
    if n['mesh'] in used_meshes:
        raise SystemExit('mesh shared by two nodes')
    used_meshes[n['mesh']] = mi
    k = mi
    bone = mi if mi in jindex else None
    while bone is None and k in parent:
        k = parent[k]
        if k in jindex:
            bone = k
            break
    if bone is None:
        print('mesh node without bone', mi, n.get('name')); continue
    G = glob(mi)
    for prim in j['meshes'][n['mesh']]['primitives']:
        at = prim['attributes']
        if 'JOINTS_0' in at:
            continue
        pos = read_vec3(at['POSITION'])
        newp = []
        for p in pos:
            newp.append(tuple(sum(G[r][c] * (p[c] if c < 3 else 1.0) for c in range(4)) for r in range(3)))
        mn = [min(p[i] for p in newp) for i in range(3)]; mx = [max(p[i] for p in newp) for i in range(3)]
        vw = add_view(b''.join(struct.pack('<3f', *p) for p in newp), 34962)
        at['POSITION'] = add_acc(vw, 5126, len(newp), 'VEC3', min=mn, max=mx)
        if 'NORMAL' in at:
            nr = read_vec3(at['NORMAL'])
            outn = []
            for v in nr:
                t = [sum(G[r][c] * v[c] for c in range(3)) for r in range(3)]
                ln = math.sqrt(sum(x * x for x in t)) or 1.0
                outn.append(tuple(x / ln for x in t))
            vw = add_view(b''.join(struct.pack('<3f', *p) for p in outn), 34962)
            at['NORMAL'] = add_acc(vw, 5126, len(outn), 'VEC3')
        cnt = len(newp)
        jv = add_view(b''.join(struct.pack('<4B', jindex[bone], 0, 0, 0) for _ in range(cnt)), 34962)
        at['JOINTS_0'] = add_acc(jv, 5121, cnt, 'VEC4')
        wv = add_view(b''.join(struct.pack('<4f', 1, 0, 0, 0) for _ in range(cnt)), 34962)
        at['WEIGHTS_0'] = add_acc(wv, 5126, cnt, 'VEC4')

# inverse bind matrices (glTF column-major)
ibm = bytearray()
for jn in joints:
    m = inv(glob(jn))
    for c in range(4):
        for r in range(4):
            ibm += struct.pack('<f', m[r][c])
iv = add_view(bytes(ibm))
ia = add_acc(iv, 5126, len(joints), 'MAT4')
j['skins'] = [{'joints': joints, 'inverseBindMatrices': ia}]
for mi in mesh_nodes:
    if nodes[mi]['mesh'] in used_meshes and any('JOINTS_0' in p['attributes'] for p in j['meshes'][nodes[mi]['mesh']]['primitives']):
        nodes[mi]['skin'] = 0
# skinned meshes ignore node transform: neutralise it so nothing double-applies
for mi in mesh_nodes:
    for key in ('translation', 'rotation', 'scale'):
        nodes[mi].pop(key, None)
pad()
j['buffers'][0]['byteLength'] = len(bin_)
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * ((4 - len(js) % 4) % 4)
binchunk = struct.pack('<I', len(bin_)) + b'BIN\0' + bytes(bin_)
total = 12 + 8 + len(js) + len(binchunk)
open(sys.argv[2], 'wb').write(b[:8] + struct.pack('<I', total) + struct.pack('<I', len(js)) + b'JSON' + js + binchunk)
print('written', total)
