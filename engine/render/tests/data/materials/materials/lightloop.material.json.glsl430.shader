{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return ivec2(0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    vec4 _546 = fa_light_texel(param);\n    return ivec2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1476 = fa_cluster_lookup(param);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    vec3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    vec3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    vec3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1762 = fa_tex_fix(param_2, param_3);\n    vec4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    vec4 _1776 = (_2418 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2377 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1808 = fa_tex_fix(param_6, param_7);\n        vec3 _1812 = (_1808 * 2.0) - vec3(1.0);\n        vec2 _1817 = _1812.xy * fa_mesh_fs_params[6].x;\n        vec3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1846 = fa_tex_fix(param_12, param_13);\n    vec4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1912 = fa_tex_fix(param_20, param_21);\n    return Surface(_1776.xyz, _1776.w, _2377, clamp(fa_mesh_fs_params[5].x * _1846.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1846.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1885.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1912));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _266 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _272 = fa_light_texel(param_1);\n    float _275 = _272.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _282 = _275 < 0.5;\n    vec3 l;\n    if (_282)\n    {\n        l = normalize(_266.xyz);\n    }\n    else\n    {\n        vec3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / vec3(max(_296, 9.9999997473787516355514526367188e-05));\n        float _311 = _296 / max(_266.w, 0.001000000047497451305389404296875);\n        float _317 = clamp(1.0 - (_311 * _311), 0.0, 1.0);\n        atten = _317 * _317;\n        if (_275 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _331 = fa_light_texel(param_2);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _348 = fa_light_texel(param_3);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5)\n            {\n                cos_inner = mix(_341, 1.0, 0.25);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _272.xyz * atten, atten, 1.0, dist, _380);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count();\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = fa_shadows[24].z;\n            }\n            else\n            {\n                _644 = fa_shadows[24].w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _682 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _687 = clamp(dot(n, l), 0.0, 1.0);\n    float _693 = sqrt(1.0 - (_687 * _687));\n    float _701 = min(_693 / max(_687, 0.20000000298023223876953125), 4.0);\n    float _706;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _706 = fa_shadows[26].y;\n    }\n    else\n    {\n        _706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _731 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_706 * _693)), 1.0);\n    float _738 = _731.x;\n    bool _741 = _738 < fa_shadows[ci * 1 + 16].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0;\n    }\n    float _784;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _784 = fa_shadows[26].x;\n    }\n    else\n    {\n        _784 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0 + (0.5 * _701))) / _682);\n    float _812 = ((fa_shadows[ci * 1 + 20].x * min(_701, 3.0)) * 0.5) / _682;\n    int _821 = int(fa_shadows[25].z + 0.5);\n    if (_821 == 1)\n    {\n        vec2 param = _731.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _832 = fa_shadow_depth(param, param_1);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = clamp(((fa_shadows[25].w * _682) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            vec2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            vec2 param_5 = _731.xy + (_875 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _886 = fa_shadow_depth(param_5, param_6);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_803 - (sum / cnt), 0.0) * _682) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        vec2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _731.xy + (_949 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _960 = fa_shadow_depth(param_10, param_11);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _990 = int(fa_shadows[25].x + 0.5);\n    if (_990 < 1)\n    {\n        return 1.0;\n    }\n    float _1006 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1073;\n        if (_1073 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1098 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1117 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1098, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1128 = clamp((_1006 - (fa_shadow_split_at(param_7) - _1117)) / _1117, 0.0, 1.0);\n        if (_1128 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1149;\n                if (_1149 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1);\n    vec3 _2353 = _1504.direction;\n    vec3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    return LightSample(_2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count();\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1363 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1366 = _1363.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1366 * _1366, exp2((-9.27999973297119140625) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625 * _1286;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1286)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1316, 0.0500000007450580596923828125 + _1316, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1286 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1405 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1405.x) + vec3(_1405.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5)\n        {\n            _1645 = 1.0;\n        }\n        else\n        {\n            _1645 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1173 = int(fa_shadows[25].x + 0.5);\n    float _1183 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2253 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    vec3 _1955 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n    Surface _1963 = fa_standard_surface(param_1);\n    vec3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    vec3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    vec3 _2290 = _1963.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2284;\n    }\n    else\n    {\n        vec3 _1984 = _2286;\n        vec3 _1985 = normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n        Surface param_5 = Surface(_2284, _2285, _1985, _2287, _2288, _2289, _2290);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2000 = result;\n    vec3 _2001 = _2000 + _2290;\n    result = _2001;\n    vec3 param_6 = _2001;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2010 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        vec3 _2027 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2034 = dot(_2027, fa_mesh_fs_params[9].xyz);\n        bool _2038 = fa_mesh_fs_params[9].w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - fa_mesh_fs_params[8].x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = fa_mesh_fs_params[7].w * _2051;\n            float tau = _2060 * _2060;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2034);\n                }\n                else\n                {\n                    _2076 = fa_mesh_fs_params[0].y;\n                }\n                float _2097 = mix(_2076, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2039, 0.0, 1.0));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - fa_mesh_fs_params[8].z;\n                float _2111 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2122 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = fa_mesh_fs_params[8].y * _2106;\n                }\n                else\n                {\n                    _2150 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = fa_mesh_fs_params[8].y * _2111;\n                }\n                else\n                {\n                    _2183 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2111, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2285);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return ivec2(0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    vec4 _546 = fa_light_texel(param);\n    return ivec2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1476 = fa_cluster_lookup(param);\n    fa_cl_slot = _1476.x;\n    fa_cl_local = _1476.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1723 = fa_linear_to_srgb(param);\n        c = _1723;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1731 = fa_srgb_to_linear(param_1);\n            c = _1731;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    vec3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    vec3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    vec3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1762 = fa_tex_fix(param_2, param_3);\n    vec4 _2418 = base_t;\n    _2418.x = _1762.x;\n    _2418.y = _1762.y;\n    _2418.z = _1762.z;\n    base_t = _2418;\n    vec4 _1776 = (_2418 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2377 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1808 = fa_tex_fix(param_6, param_7);\n        vec3 _1812 = (_1808 * 2.0) - vec3(1.0);\n        vec2 _1817 = _1812.xy * fa_mesh_fs_params[6].x;\n        vec3 _2426 = _1812;\n        _2426.x = _1817.x;\n        _2426.y = _1817.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2426;\n        _2377 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1846 = fa_tex_fix(param_12, param_13);\n    vec4 _2429 = mrt;\n    _2429.x = _1846.x;\n    _2429.y = _1846.y;\n    _2429.z = _1846.z;\n    mrt = _2429;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1885 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1912 = fa_tex_fix(param_20, param_21);\n    return Surface(_1776.xyz, _1776.w, _2377, clamp(fa_mesh_fs_params[5].x * _1846.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1846.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1885.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1912));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _266 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _272 = fa_light_texel(param_1);\n    float _275 = _272.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _282 = _275 < 0.5;\n    vec3 l;\n    if (_282)\n    {\n        l = normalize(_266.xyz);\n    }\n    else\n    {\n        vec3 _294 = _266.xyz - world_pos;\n        float _296 = length(_294);\n        dist = _296;\n        l = _294 / vec3(max(_296, 9.9999997473787516355514526367188e-05));\n        float _311 = _296 / max(_266.w, 0.001000000047497451305389404296875);\n        float _317 = clamp(1.0 - (_311 * _311), 0.0, 1.0);\n        atten = _317 * _317;\n        if (_275 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _331 = fa_light_texel(param_2);\n            float _341 = _331.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _348 = fa_light_texel(param_3);\n            float _349 = _348.x;\n            float cos_inner = _349;\n            if (_349 > 1.5)\n            {\n                cos_inner = mix(_341, 1.0, 0.25);\n            }\n            atten *= smoothstep(_341, cos_inner, dot(-l, normalize(_331.xyz)));\n        }\n    }\n    int _380;\n    if (_282)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_275 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _272.xyz * atten, atten, 1.0, dist, _380);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1561 = n < 0;\n    bool _1568;\n    if (!_1561)\n    {\n        _1568 = n >= fa_light_count();\n    }\n    else\n    {\n        _1568 = _1561;\n    }\n    if (_1568)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = fa_shadows[24].z;\n            }\n            else\n            {\n                _644 = fa_shadows[24].w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _682 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _687 = clamp(dot(n, l), 0.0, 1.0);\n    float _693 = sqrt(1.0 - (_687 * _687));\n    float _701 = min(_693 / max(_687, 0.20000000298023223876953125), 4.0);\n    float _706;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _706 = fa_shadows[26].y;\n    }\n    else\n    {\n        _706 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _731 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_706 * _693)), 1.0);\n    float _738 = _731.x;\n    bool _741 = _738 < fa_shadows[ci * 1 + 16].x;\n    bool _750;\n    if (!_741)\n    {\n        _750 = _738 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _731.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _768;\n    if (!_759)\n    {\n        _768 = _731.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _768 = _759;\n    }\n    bool _775;\n    if (!_768)\n    {\n        _775 = _731.z > 1.0;\n    }\n    else\n    {\n        _775 = _768;\n    }\n    if (_775)\n    {\n        return -1.0;\n    }\n    float _784;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _784 = fa_shadows[26].x;\n    }\n    else\n    {\n        _784 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _803 = _731.z - ((_784 * (1.0 + (0.5 * _701))) / _682);\n    float _812 = ((fa_shadows[ci * 1 + 20].x * min(_701, 3.0)) * 0.5) / _682;\n    int _821 = int(fa_shadows[25].z + 0.5);\n    if (_821 == 1)\n    {\n        vec2 param = _731.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _832 = fa_shadow_depth(param, param_1);\n        return float(_803 <= _832);\n    }\n    float _839 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _842 = _821 == 2;\n    if (_842)\n    {\n        float _856 = clamp(((fa_shadows[25].w * _682) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _839;\n            vec2 _875 = fa_shadow_vogel(param_2, param_3, param_4) * _856;\n            vec2 param_5 = _731.xy + (_875 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _886 = fa_shadow_depth(param_5, param_6);\n            if (_886 < (_803 - (length(_875) * _812)))\n            {\n                sum += _886;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_803 - (sum / cnt), 0.0) * _682) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _930 = _842 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _930; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _930;\n        float param_9 = _839;\n        vec2 _949 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _731.xy + (_949 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _960 = fa_shadow_depth(param_10, param_11);\n        lit += float((_803 - (length(_949) * _812)) <= _960);\n    }\n    return lit / float(_930);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _990 = int(fa_shadows[25].x + 0.5);\n    if (_990 < 1)\n    {\n        return 1.0;\n    }\n    float _1006 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _990 - 1;\n    if (_1006 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1018 = _990 > 1;\n    bool _1025;\n    if (_1018)\n    {\n        _1025 = _1006 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1025 = _1018;\n    }\n    if (_1025)\n    {\n        ci = 1;\n    }\n    bool _1029 = _990 > 2;\n    bool _1036;\n    if (_1029)\n    {\n        _1036 = _1006 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1036 = _1029;\n    }\n    if (_1036)\n    {\n        ci = 2;\n    }\n    bool _1040 = _990 > 3;\n    bool _1047;\n    if (_1040)\n    {\n        _1047 = _1006 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1047 = _1040;\n    }\n    if (_1047)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _990)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1073 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1073;\n        if (_1073 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1098;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1098 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1098 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1117 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1098, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1128 = clamp((_1006 - (fa_shadow_split_at(param_7) - _1117)) / _1117, 0.0, 1.0);\n        if (_1128 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _990)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1149 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1149;\n                if (_1149 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1128);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1504 = fa_light_sample(param, param_1);\n    vec3 _2353 = _1504.direction;\n    vec3 _2348 = _1504.color;\n    float _2350 = _1504.shadow;\n    int _2358 = _1504.type;\n    if ((_2358 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2353;\n        float _1518 = fa_shadow_factor(param_2, param_3);\n        _2350 = _1518;\n        _2348 *= _1518;\n    }\n    return LightSample(_2353, _2348, _1504.attenuation, _2350, _1504._distance, _2358);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1535 = n < 0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = n >= fa_light_count();\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    if (_1542)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1363 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1366 = _1363.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1366 * _1366, exp2((-9.27999973297119140625) * ndv)) * _1366) + _1363.y)) + _1363.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1286 = rough * rough;\n    float _1316 = 0.60000002384185791015625 * _1286;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1286)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1316, 0.0500000007450580596923828125 + _1316, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1286 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1405 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1405.x) + vec3(_1405.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1608 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1608 > bestPower)\n        {\n            bestPower = _1608;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1637 = fa_light(param_2, param_3);\n        float _1645;\n        if (dot(s.normal, _1637.direction) > 0.5)\n        {\n            _1645 = 1.0;\n        }\n        else\n        {\n            _1645 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1637.color) * _1645);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1173 = int(fa_shadows[25].x + 0.5);\n    float _1183 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1188 = _1173 > 0;\n    bool _1197;\n    if (_1188)\n    {\n        int param = _1173 - 1;\n        _1197 = _1183 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1197 = _1188;\n    }\n    if (_1197)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1204 = _1173 > 1;\n        bool _1211;\n        if (_1204)\n        {\n            _1211 = _1183 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1211 = _1204;\n        }\n        if (_1211)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1217 = _1173 > 2;\n        bool _1224;\n        if (_1217)\n        {\n            _1224 = _1183 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1224 = _1217;\n        }\n        if (_1224)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1230 = _1173 > 3;\n        bool _1237;\n        if (_1230)\n        {\n            _1237 = _1183 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1237 = _1230;\n        }\n        if (_1237)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2253 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2253 = -_2253;\n    }\n    vec3 _1955 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n    Surface _1963 = fa_standard_surface(param_1);\n    vec3 _2284 = _1963.albedo;\n    float _2285 = _1963.alpha;\n    vec3 _2286 = _1963.normal;\n    float _2287 = _1963.metallic;\n    float _2288 = _1963.roughness;\n    float _2289 = _1963.occlusion;\n    vec3 _2290 = _1963.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n    Surface param_3 = _1963;\n    surface(param_2, param_3);\n    _2284 = param_3.albedo;\n    _2285 = param_3.alpha;\n    _2286 = param_3.normal;\n    _2287 = param_3.metallic;\n    _2288 = param_3.roughness;\n    _2289 = param_3.occlusion;\n    _2290 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2284;\n    }\n    else\n    {\n        vec3 _1984 = _2286;\n        vec3 _1985 = normalize(_1984);\n        _2286 = _1985;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2253, fa_world_tangent, fa_uv, fa_vertex_color, _1955, gl_FrontFacing);\n        Surface param_5 = Surface(_2284, _2285, _1985, _2287, _2288, _2289, _2290);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2000 = result;\n    vec3 _2001 = _2000 + _2290;\n    result = _2001;\n    vec3 param_6 = _2001;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2010 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        vec3 _2027 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2034 = dot(_2027, fa_mesh_fs_params[9].xyz);\n        bool _2038 = fa_mesh_fs_params[9].w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - fa_mesh_fs_params[8].x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = fa_mesh_fs_params[7].w * _2051;\n            float tau = _2060 * _2060;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2034);\n                }\n                else\n                {\n                    _2076 = fa_mesh_fs_params[0].y;\n                }\n                float _2097 = mix(_2076, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2039, 0.0, 1.0));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - fa_mesh_fs_params[8].z;\n                float _2111 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2122 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = fa_mesh_fs_params[8].y * _2106;\n                }\n                else\n                {\n                    _2150 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = fa_mesh_fs_params[8].y * _2111;\n                }\n                else\n                {\n                    _2183 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2111, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2285);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_394",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_630",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1651",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    vec4 _241 = (_590 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _571 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _571, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _590 = base_t;\n    _590.x = _225.x;\n    _590.y = _225.y;\n    _590.z = _225.z;\n    base_t = _590;\n    vec4 _241 = (_590 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _571 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _598 = _279;\n        _598.x = _284.x;\n        _598.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _598;\n        _571 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _601 = mrt;\n    _601.x = _313.x;\n    _601.y = _313.y;\n    _601.z = _313.z;\n    mrt = _601;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _571, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _518 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _518 = -_518;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _518, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
