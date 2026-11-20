{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _374 = fa_mesh_fs_params[19].x < 0.0;\n    bool _381;\n    if (!_374)\n    {\n        _381 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _389;\n    if (!_381)\n    {\n        _389 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _389 = _381;\n    }\n    bool _396;\n    if (!_389)\n    {\n        _396 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _396 = _389;\n    }\n    bool _403;\n    if (!_396)\n    {\n        _403 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    if (_403)\n    {\n        return ivec2(0);\n    }\n    vec4 _413 = vec4(world_pos, 1.0);\n    float _420 = dot(fa_mesh_fs_params[16], _413);\n    if (!(_420 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _442 = vec2(dot(fa_mesh_fs_params[14], _413), dot(fa_mesh_fs_params[15], _413)) / vec2(_420);\n    int _446 = int(fa_mesh_fs_params[18].x);\n    int _450 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _450) + clamp(int(floor(((_442.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _450 - 1)) * _446)) + clamp(int(floor(((_442.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _446 - 1);\n    vec4 _521 = fa_light_texel(param);\n    return ivec2(int(_521.x), int(_521.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1266 = fa_cluster_lookup(param);\n    fa_cl_slot = _1266.x;\n    fa_cl_local = _1266.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1374 = fa_linear_to_srgb(param);\n        c = _1374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1382 = fa_srgb_to_linear(param_1);\n            c = _1382;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _150;\n    if (i.front_facing)\n    {\n        _150 = i.world_normal;\n    }\n    else\n    {\n        _150 = -i.world_normal;\n    }\n    vec3 _174 = normalize(i.world_tangent.xyz - (_150 * dot(_150, i.world_tangent.xyz)));\n    vec3 _202 = normalize(((_174 * m.x) + ((cross(_150, _174) * i.world_tangent.w) * m.y)) + (_150 * m.z));\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = _202;\n    }\n    else\n    {\n        _205 = -_202;\n    }\n    return _205;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1413 = fa_tex_fix(param_2, param_3);\n    vec4 _2118 = base_t;\n    _2118.x = _1413.x;\n    _2118.y = _1413.y;\n    _2118.z = _1413.z;\n    base_t = _2118;\n    vec4 _1427 = (_2118 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2083 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1459 = fa_tex_fix(param_6, param_7);\n        vec3 _1463 = (_1459 * 2.0) - vec3(1.0);\n        vec2 _1468 = _1463.xy * fa_mesh_fs_params[6].x;\n        vec3 _2126 = _1463;\n        _2126.x = _1468.x;\n        _2126.y = _1468.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2126;\n        _2083 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1497 = fa_tex_fix(param_12, param_13);\n    vec4 _2129 = mrt;\n    _2129.x = _1497.x;\n    _2129.y = _1497.y;\n    _2129.z = _1497.z;\n    mrt = _2129;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1537 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1564 = fa_tex_fix(param_20, param_21);\n    return Surface(_1427.xyz, _1427.w, _2083, clamp(fa_mesh_fs_params[5].x * _1497.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1497.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1537.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1564));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _242 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _248 = fa_light_texel(param_1);\n    float _251 = _248.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _258 = _251 < 0.5;\n    vec3 l;\n    if (_258)\n    {\n        l = normalize(_242.xyz);\n    }\n    else\n    {\n        vec3 _270 = _242.xyz - world_pos;\n        float _272 = length(_270);\n        dist = _272;\n        l = _270 / vec3(max(_272, 9.9999997473787516355514526367188e-05));\n        float _287 = _272 / max(_242.w, 0.001000000047497451305389404296875);\n        float _293 = clamp(1.0 - (_287 * _287), 0.0, 1.0);\n        atten = _293 * _293;\n        if (_251 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _307 = fa_light_texel(param_2);\n            float _317 = _307.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _324 = fa_light_texel(param_3);\n            float _325 = _324.x;\n            float cos_inner = _325;\n            if (_325 > 1.5)\n            {\n                cos_inner = mix(_317, 1.0, 0.25);\n            }\n            atten *= smoothstep(_317, cos_inner, dot(-l, normalize(_307.xyz)));\n        }\n    }\n    int _355;\n    if (_258)\n    {\n        _355 = 0;\n    }\n    else\n    {\n        _355 = (_251 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _248.xyz * atten, atten, 1.0, dist, _355);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _595;\n    if (i == 0)\n    {\n        _595 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _611;\n        if (i == 1)\n        {\n            _611 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _619;\n            if (i == 2)\n            {\n                _619 = fa_shadows[24].z;\n            }\n            else\n            {\n                _619 = fa_shadows[24].w;\n            }\n            _611 = _619;\n        }\n        _595 = _611;\n    }\n    return _595;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _583 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_583), sin(_583)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _657 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _662 = clamp(dot(n, l), 0.0, 1.0);\n    float _668 = sqrt(1.0 - (_662 * _662));\n    float _676 = min(_668 / max(_662, 0.20000000298023223876953125), 4.0);\n    float _681;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _681 = fa_shadows[26].y;\n    }\n    else\n    {\n        _681 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _706 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_681 * _668)), 1.0);\n    float _713 = _706.x;\n    bool _716 = _713 < fa_shadows[ci * 1 + 16].x;\n    bool _725;\n    if (!_716)\n    {\n        _725 = _713 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _725 = _716;\n    }\n    bool _734;\n    if (!_725)\n    {\n        _734 = _706.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _734 = _725;\n    }\n    bool _743;\n    if (!_734)\n    {\n        _743 = _706.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _743 = _734;\n    }\n    bool _750;\n    if (!_743)\n    {\n        _750 = _706.z > 1.0;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return -1.0;\n    }\n    float _759;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _759 = fa_shadows[26].x;\n    }\n    else\n    {\n        _759 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _778 = _706.z - ((_759 * (1.0 + (0.5 * _676))) / _657);\n    float _787 = ((fa_shadows[ci * 1 + 20].x * min(_676, 3.0)) * 0.5) / _657;\n    int _796 = int(fa_shadows[25].z + 0.5);\n    if (_796 == 1)\n    {\n        vec2 param = _706.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _807 = fa_shadow_depth(param, param_1);\n        return float(_778 <= _807);\n    }\n    float _814 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _817 = _796 == 2;\n    if (_817)\n    {\n        float _831 = clamp(((fa_shadows[25].w * _657) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _814;\n            vec2 _850 = fa_shadow_vogel(param_2, param_3, param_4) * _831;\n            vec2 param_5 = _706.xy + (_850 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _861 = fa_shadow_depth(param_5, param_6);\n            if (_861 < (_778 - (length(_850) * _787)))\n            {\n                sum += _861;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_778 - (sum / cnt), 0.0) * _657) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _905 = _817 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _905; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _905;\n        float param_9 = _814;\n        vec2 _924 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _706.xy + (_924 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _935 = fa_shadow_depth(param_10, param_11);\n        lit += float((_778 - (length(_924) * _787)) <= _935);\n    }\n    return lit / float(_905);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _965 = int(fa_shadows[25].x + 0.5);\n    if (_965 < 1)\n    {\n        return 1.0;\n    }\n    float _981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _965 - 1;\n    if (_981 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _993 = _965 > 1;\n    bool _1000;\n    if (_993)\n    {\n        _1000 = _981 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1000 = _993;\n    }\n    if (_1000)\n    {\n        ci = 1;\n    }\n    bool _1004 = _965 > 2;\n    bool _1011;\n    if (_1004)\n    {\n        _1011 = _981 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1011 = _1004;\n    }\n    if (_1011)\n    {\n        ci = 2;\n    }\n    bool _1015 = _965 > 3;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _981 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _965)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1048;\n        if (_1048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1073 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1092 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1103 = clamp((_981 - (fa_shadow_split_at(param_7) - _1092)) / _1092, 0.0, 1.0);\n        if (_1103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _965)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1124;\n                if (_1124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1294 = fa_light_sample(param, param_1);\n    vec3 _2068 = _1294.direction;\n    vec3 _2063 = _1294.color;\n    float _2065 = _1294.shadow;\n    int _2073 = _1294.type;\n    if ((_2073 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2068;\n        float _1308 = fa_shadow_factor(param_2, param_3);\n        _2065 = _1308;\n        _2063 *= _1308;\n    }\n    return LightSample(_2068, _2063, _1294.attenuation, _2065, _1294._distance, _2073);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1148 = int(fa_shadows[25].x + 0.5);\n    float _1158 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1163 = _1148 > 0;\n    bool _1172;\n    if (_1163)\n    {\n        int param = _1148 - 1;\n        _1172 = _1158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1172 = _1163;\n    }\n    if (_1172)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1179 = _1148 > 1;\n        bool _1186;\n        if (_1179)\n        {\n            _1186 = _1158 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1186 = _1179;\n        }\n        if (_1186)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1192 = _1148 > 2;\n        bool _1199;\n        if (_1192)\n        {\n            _1199 = _1158 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1199 = _1192;\n        }\n        if (_1199)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1205 = _1148 > 3;\n        bool _1212;\n        if (_1205)\n        {\n            _1212 = _1158 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1212 = _1205;\n        }\n        if (_1212)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1946 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1946 = -_1946;\n    }\n    vec3 _1607 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n    Surface _1615 = fa_standard_surface(param_1);\n    vec3 _1985 = _1615.albedo;\n    float _1986 = _1615.alpha;\n    vec3 _1987 = _1615.normal;\n    float _1988 = _1615.metallic;\n    float _1989 = _1615.roughness;\n    float _1990 = _1615.occlusion;\n    vec3 _1991 = _1615.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n    Surface param_3 = _1615;\n    surface(param_2, param_3);\n    _1985 = param_3.albedo;\n    _1986 = param_3.alpha;\n    _1987 = param_3.normal;\n    _1988 = param_3.metallic;\n    _1989 = param_3.roughness;\n    _1990 = param_3.occlusion;\n    _1991 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1985;\n    }\n    else\n    {\n        vec3 _1636 = _1987;\n        vec3 _1637 = normalize(_1636);\n        _1987 = _1637;\n        vec3 param_4 = _1637;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n        Surface param_6 = Surface(_1985, _1986, _1987, _1988, _1989, _1990, _1991);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _1656 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1656; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _1946;\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n            Surface param_13 = Surface(_1985, _1986, _1987, _1988, _1989, _1990, _1991);\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _1693 = result;\n    vec3 _1694 = _1693 + _1991;\n    result = _1694;\n    vec3 param_15 = _1694;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _1703 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1711;\n    if (!_1703)\n    {\n        _1711 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1711 = _1703;\n    }\n    if (_1711)\n    {\n        vec3 _1720 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1727 = dot(_1720, fa_mesh_fs_params[9].xyz);\n        bool _1731 = fa_mesh_fs_params[9].w > 0.5;\n        float _1732;\n        if (_1731)\n        {\n            _1732 = _1727;\n        }\n        else\n        {\n            _1732 = length(_1720);\n        }\n        float _1744 = _1732 - fa_mesh_fs_params[8].x;\n        if (_1744 > 0.0)\n        {\n            float _1753 = fa_mesh_fs_params[7].w * _1744;\n            float tau = _1753 * _1753;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1769;\n                if (_1731)\n                {\n                    _1769 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1727);\n                }\n                else\n                {\n                    _1769 = fa_mesh_fs_params[0].y;\n                }\n                float _1790 = mix(_1769, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1732, 0.0, 1.0));\n                float _1794 = fa_world_pos.y - _1790;\n                float _1799 = _1790 - fa_mesh_fs_params[8].z;\n                float _1804 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1807 = _1799 <= 0.0;\n                bool _1808 = !_1807;\n                bool _1814;\n                if (_1808)\n                {\n                    _1814 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1814 = _1807;\n                }\n                float _1815;\n                if (_1814)\n                {\n                    _1815 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1815 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1799, 80.0));\n                }\n                bool _1842;\n                if (_1808)\n                {\n                    _1842 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1842 = _1807;\n                }\n                float _1843;\n                if (_1842)\n                {\n                    _1843 = fa_mesh_fs_params[8].y * _1799;\n                }\n                else\n                {\n                    _1843 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1799, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1868 = _1804 <= 0.0;\n                bool _1875;\n                if (!_1868)\n                {\n                    _1875 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1875 = _1868;\n                }\n                float _1876;\n                if (_1875)\n                {\n                    _1876 = fa_mesh_fs_params[8].y * _1804;\n                }\n                else\n                {\n                    _1876 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1804, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1903;\n                if (abs(_1794) < 0.001000000047497451305389404296875)\n                {\n                    _1903 = _1815;\n                }\n                else\n                {\n                    _1903 = (_1876 - _1843) / _1794;\n                }\n                tau += (_1744 * max(_1903, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _1986);\n}\n\n",
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
            "inst_name": "_369",
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
            "inst_name": "_605",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_386, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _374 = fa_mesh_fs_params[19].x < 0.0;\n    bool _381;\n    if (!_374)\n    {\n        _381 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _381 = _374;\n    }\n    bool _389;\n    if (!_381)\n    {\n        _389 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _389 = _381;\n    }\n    bool _396;\n    if (!_389)\n    {\n        _396 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _396 = _389;\n    }\n    bool _403;\n    if (!_396)\n    {\n        _403 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _403 = _396;\n    }\n    if (_403)\n    {\n        return ivec2(0);\n    }\n    vec4 _413 = vec4(world_pos, 1.0);\n    float _420 = dot(fa_mesh_fs_params[16], _413);\n    if (!(_420 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _442 = vec2(dot(fa_mesh_fs_params[14], _413), dot(fa_mesh_fs_params[15], _413)) / vec2(_420);\n    int _446 = int(fa_mesh_fs_params[18].x);\n    int _450 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _450) + clamp(int(floor(((_442.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _450 - 1)) * _446)) + clamp(int(floor(((_442.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _446 - 1);\n    vec4 _521 = fa_light_texel(param);\n    return ivec2(int(_521.x), int(_521.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1266 = fa_cluster_lookup(param);\n    fa_cl_slot = _1266.x;\n    fa_cl_local = _1266.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1374 = fa_linear_to_srgb(param);\n        c = _1374;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1382 = fa_srgb_to_linear(param_1);\n            c = _1382;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _150;\n    if (i.front_facing)\n    {\n        _150 = i.world_normal;\n    }\n    else\n    {\n        _150 = -i.world_normal;\n    }\n    vec3 _174 = normalize(i.world_tangent.xyz - (_150 * dot(_150, i.world_tangent.xyz)));\n    vec3 _202 = normalize(((_174 * m.x) + ((cross(_150, _174) * i.world_tangent.w) * m.y)) + (_150 * m.z));\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = _202;\n    }\n    else\n    {\n        _205 = -_202;\n    }\n    return _205;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1413 = fa_tex_fix(param_2, param_3);\n    vec4 _2118 = base_t;\n    _2118.x = _1413.x;\n    _2118.y = _1413.y;\n    _2118.z = _1413.z;\n    base_t = _2118;\n    vec4 _1427 = (_2118 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2083 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1459 = fa_tex_fix(param_6, param_7);\n        vec3 _1463 = (_1459 * 2.0) - vec3(1.0);\n        vec2 _1468 = _1463.xy * fa_mesh_fs_params[6].x;\n        vec3 _2126 = _1463;\n        _2126.x = _1468.x;\n        _2126.y = _1468.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2126;\n        _2083 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1497 = fa_tex_fix(param_12, param_13);\n    vec4 _2129 = mrt;\n    _2129.x = _1497.x;\n    _2129.y = _1497.y;\n    _2129.z = _1497.z;\n    mrt = _2129;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1537 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1564 = fa_tex_fix(param_20, param_21);\n    return Surface(_1427.xyz, _1427.w, _2083, clamp(fa_mesh_fs_params[5].x * _1497.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1497.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1537.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1564));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _242 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _248 = fa_light_texel(param_1);\n    float _251 = _248.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _258 = _251 < 0.5;\n    vec3 l;\n    if (_258)\n    {\n        l = normalize(_242.xyz);\n    }\n    else\n    {\n        vec3 _270 = _242.xyz - world_pos;\n        float _272 = length(_270);\n        dist = _272;\n        l = _270 / vec3(max(_272, 9.9999997473787516355514526367188e-05));\n        float _287 = _272 / max(_242.w, 0.001000000047497451305389404296875);\n        float _293 = clamp(1.0 - (_287 * _287), 0.0, 1.0);\n        atten = _293 * _293;\n        if (_251 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _307 = fa_light_texel(param_2);\n            float _317 = _307.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _324 = fa_light_texel(param_3);\n            float _325 = _324.x;\n            float cos_inner = _325;\n            if (_325 > 1.5)\n            {\n                cos_inner = mix(_317, 1.0, 0.25);\n            }\n            atten *= smoothstep(_317, cos_inner, dot(-l, normalize(_307.xyz)));\n        }\n    }\n    int _355;\n    if (_258)\n    {\n        _355 = 0;\n    }\n    else\n    {\n        _355 = (_251 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _248.xyz * atten, atten, 1.0, dist, _355);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _595;\n    if (i == 0)\n    {\n        _595 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _611;\n        if (i == 1)\n        {\n            _611 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _619;\n            if (i == 2)\n            {\n                _619 = fa_shadows[24].z;\n            }\n            else\n            {\n                _619 = fa_shadows[24].w;\n            }\n            _611 = _619;\n        }\n        _595 = _611;\n    }\n    return _595;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _583 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_583), sin(_583)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _657 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _662 = clamp(dot(n, l), 0.0, 1.0);\n    float _668 = sqrt(1.0 - (_662 * _662));\n    float _676 = min(_668 / max(_662, 0.20000000298023223876953125), 4.0);\n    float _681;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _681 = fa_shadows[26].y;\n    }\n    else\n    {\n        _681 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _706 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_681 * _668)), 1.0);\n    float _713 = _706.x;\n    bool _716 = _713 < fa_shadows[ci * 1 + 16].x;\n    bool _725;\n    if (!_716)\n    {\n        _725 = _713 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _725 = _716;\n    }\n    bool _734;\n    if (!_725)\n    {\n        _734 = _706.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _734 = _725;\n    }\n    bool _743;\n    if (!_734)\n    {\n        _743 = _706.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _743 = _734;\n    }\n    bool _750;\n    if (!_743)\n    {\n        _750 = _706.z > 1.0;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return -1.0;\n    }\n    float _759;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _759 = fa_shadows[26].x;\n    }\n    else\n    {\n        _759 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _778 = _706.z - ((_759 * (1.0 + (0.5 * _676))) / _657);\n    float _787 = ((fa_shadows[ci * 1 + 20].x * min(_676, 3.0)) * 0.5) / _657;\n    int _796 = int(fa_shadows[25].z + 0.5);\n    if (_796 == 1)\n    {\n        vec2 param = _706.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _807 = fa_shadow_depth(param, param_1);\n        return float(_778 <= _807);\n    }\n    float _814 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _817 = _796 == 2;\n    if (_817)\n    {\n        float _831 = clamp(((fa_shadows[25].w * _657) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _814;\n            vec2 _850 = fa_shadow_vogel(param_2, param_3, param_4) * _831;\n            vec2 param_5 = _706.xy + (_850 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _861 = fa_shadow_depth(param_5, param_6);\n            if (_861 < (_778 - (length(_850) * _787)))\n            {\n                sum += _861;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_778 - (sum / cnt), 0.0) * _657) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _905 = _817 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _905; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _905;\n        float param_9 = _814;\n        vec2 _924 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _706.xy + (_924 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _935 = fa_shadow_depth(param_10, param_11);\n        lit += float((_778 - (length(_924) * _787)) <= _935);\n    }\n    return lit / float(_905);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _965 = int(fa_shadows[25].x + 0.5);\n    if (_965 < 1)\n    {\n        return 1.0;\n    }\n    float _981 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _965 - 1;\n    if (_981 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _993 = _965 > 1;\n    bool _1000;\n    if (_993)\n    {\n        _1000 = _981 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1000 = _993;\n    }\n    if (_1000)\n    {\n        ci = 1;\n    }\n    bool _1004 = _965 > 2;\n    bool _1011;\n    if (_1004)\n    {\n        _1011 = _981 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1011 = _1004;\n    }\n    if (_1011)\n    {\n        ci = 2;\n    }\n    bool _1015 = _965 > 3;\n    bool _1022;\n    if (_1015)\n    {\n        _1022 = _981 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1022 = _1015;\n    }\n    if (_1022)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _965)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1048 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1048;\n        if (_1048 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1073;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1073 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1073 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1092 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1073, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1103 = clamp((_981 - (fa_shadow_split_at(param_7) - _1092)) / _1092, 0.0, 1.0);\n        if (_1103 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _965)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1124 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1124;\n                if (_1124 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1103);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1294 = fa_light_sample(param, param_1);\n    vec3 _2068 = _1294.direction;\n    vec3 _2063 = _1294.color;\n    float _2065 = _1294.shadow;\n    int _2073 = _1294.type;\n    if ((_2073 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2068;\n        float _1308 = fa_shadow_factor(param_2, param_3);\n        _2065 = _1308;\n        _2063 *= _1308;\n    }\n    return LightSample(_2068, _2063, _1294.attenuation, _2065, _1294._distance, _2073);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1148 = int(fa_shadows[25].x + 0.5);\n    float _1158 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1163 = _1148 > 0;\n    bool _1172;\n    if (_1163)\n    {\n        int param = _1148 - 1;\n        _1172 = _1158 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1172 = _1163;\n    }\n    if (_1172)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1179 = _1148 > 1;\n        bool _1186;\n        if (_1179)\n        {\n            _1186 = _1158 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1186 = _1179;\n        }\n        if (_1186)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1192 = _1148 > 2;\n        bool _1199;\n        if (_1192)\n        {\n            _1199 = _1158 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1199 = _1192;\n        }\n        if (_1199)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1205 = _1148 > 3;\n        bool _1212;\n        if (_1205)\n        {\n            _1212 = _1158 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1212 = _1205;\n        }\n        if (_1212)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1946 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1946 = -_1946;\n    }\n    vec3 _1607 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n    Surface _1615 = fa_standard_surface(param_1);\n    vec3 _1985 = _1615.albedo;\n    float _1986 = _1615.alpha;\n    vec3 _1987 = _1615.normal;\n    float _1988 = _1615.metallic;\n    float _1989 = _1615.roughness;\n    float _1990 = _1615.occlusion;\n    vec3 _1991 = _1615.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n    Surface param_3 = _1615;\n    surface(param_2, param_3);\n    _1985 = param_3.albedo;\n    _1986 = param_3.alpha;\n    _1987 = param_3.normal;\n    _1988 = param_3.metallic;\n    _1989 = param_3.roughness;\n    _1990 = param_3.occlusion;\n    _1991 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _1985;\n    }\n    else\n    {\n        vec3 _1636 = _1987;\n        vec3 _1637 = normalize(_1636);\n        _1987 = _1637;\n        vec3 param_4 = _1637;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n        Surface param_6 = Surface(_1985, _1986, _1987, _1988, _1989, _1990, _1991);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _1656 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1656; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _1946;\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _1946, fa_world_tangent, fa_uv, fa_vertex_color, _1607, gl_FrontFacing);\n            Surface param_13 = Surface(_1985, _1986, _1987, _1988, _1989, _1990, _1991);\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _1693 = result;\n    vec3 _1694 = _1693 + _1991;\n    result = _1694;\n    vec3 param_15 = _1694;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _1703 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1711;\n    if (!_1703)\n    {\n        _1711 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1711 = _1703;\n    }\n    if (_1711)\n    {\n        vec3 _1720 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1727 = dot(_1720, fa_mesh_fs_params[9].xyz);\n        bool _1731 = fa_mesh_fs_params[9].w > 0.5;\n        float _1732;\n        if (_1731)\n        {\n            _1732 = _1727;\n        }\n        else\n        {\n            _1732 = length(_1720);\n        }\n        float _1744 = _1732 - fa_mesh_fs_params[8].x;\n        if (_1744 > 0.0)\n        {\n            float _1753 = fa_mesh_fs_params[7].w * _1744;\n            float tau = _1753 * _1753;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1769;\n                if (_1731)\n                {\n                    _1769 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1727);\n                }\n                else\n                {\n                    _1769 = fa_mesh_fs_params[0].y;\n                }\n                float _1790 = mix(_1769, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1732, 0.0, 1.0));\n                float _1794 = fa_world_pos.y - _1790;\n                float _1799 = _1790 - fa_mesh_fs_params[8].z;\n                float _1804 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1807 = _1799 <= 0.0;\n                bool _1808 = !_1807;\n                bool _1814;\n                if (_1808)\n                {\n                    _1814 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1814 = _1807;\n                }\n                float _1815;\n                if (_1814)\n                {\n                    _1815 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1815 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1799, 80.0));\n                }\n                bool _1842;\n                if (_1808)\n                {\n                    _1842 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1842 = _1807;\n                }\n                float _1843;\n                if (_1842)\n                {\n                    _1843 = fa_mesh_fs_params[8].y * _1799;\n                }\n                else\n                {\n                    _1843 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1799, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1868 = _1804 <= 0.0;\n                bool _1875;\n                if (!_1868)\n                {\n                    _1875 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1875 = _1868;\n                }\n                float _1876;\n                if (_1875)\n                {\n                    _1876 = fa_mesh_fs_params[8].y * _1804;\n                }\n                else\n                {\n                    _1876 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1804, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1903;\n                if (abs(_1794) < 0.001000000047497451305389404296875)\n                {\n                    _1903 = _1815;\n                }\n                else\n                {\n                    _1903 = (_1876 - _1843) / _1794;\n                }\n                tau += (_1744 * max(_1903, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _1986);\n}\n\n",
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
            "inst_name": "_369",
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
            "inst_name": "_605",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    vec4 _241 = (_587 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _568 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _568, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _515 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _587 = base_t;\n    _587.x = _225.x;\n    _587.y = _225.y;\n    _587.z = _225.z;\n    base_t = _587;\n    vec4 _241 = (_587 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _568 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _595 = _279;\n        _595.x = _284.x;\n        _595.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _595;\n        _568 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _598 = mrt;\n    _598.x = _313.x;\n    _598.y = _313.y;\n    _598.z = _313.z;\n    mrt = _598;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _568, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _515 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _515 = -_515;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _515, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
