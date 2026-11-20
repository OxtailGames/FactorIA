{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _393 = fa_mesh_fs_params[19].x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return ivec2(0);\n    }\n    vec4 _432 = vec4(world_pos, 1.0);\n    float _439 = dot(fa_mesh_fs_params[16], _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _461 = vec2(dot(fa_mesh_fs_params[14], _432), dot(fa_mesh_fs_params[15], _432)) / vec2(_439);\n    int _465 = int(fa_mesh_fs_params[18].x);\n    int _469 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _465 - 1);\n    vec4 _540 = fa_light_texel(param);\n    return ivec2(int(_540.x), int(_540.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1668 = fa_cluster_lookup(param);\n    fa_cl_slot = _1668.x;\n    fa_cl_local = _1668.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1825 = fa_linear_to_srgb(param);\n        c = _1825;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1833 = fa_srgb_to_linear(param_1);\n            c = _1833;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    vec3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    vec3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    vec3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1864 = fa_tex_fix(param_2, param_3);\n    vec4 _2782 = base_t;\n    _2782.x = _1864.x;\n    _2782.y = _1864.y;\n    _2782.z = _1864.z;\n    base_t = _2782;\n    vec4 _1878 = (_2782 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2697 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1910 = fa_tex_fix(param_6, param_7);\n        vec3 _1914 = (_1910 * 2.0) - vec3(1.0);\n        vec2 _1919 = _1914.xy * fa_mesh_fs_params[6].x;\n        vec3 _2790 = _1914;\n        _2790.x = _1919.x;\n        _2790.y = _1919.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2790;\n        _2697 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1948 = fa_tex_fix(param_12, param_13);\n    vec4 _2793 = mrt;\n    _2793.x = _1948.x;\n    _2793.y = _1948.y;\n    _2793.z = _1948.z;\n    mrt = _2793;\n    vec4 _1977 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1977.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1989 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2019 = fa_tex_fix(param_20, param_21);\n    float _2702 = fa_mesh_fs_params[20].x;\n    float _2703 = fa_mesh_fs_params[20].y;\n    float _2706 = fa_mesh_fs_params[20].z;\n    float _2705 = fa_mesh_fs_params[21].w;\n    float _2708 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2702 *= _1989.y;\n            _2703 *= _1989.z;\n            _2705 *= _1977.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2706 *= mrt.x;\n            _2708 *= mrt.w;\n        }\n    }\n    return Surface(_1878.xyz, _1878.w, _2697, clamp(fa_mesh_fs_params[5].x * _1948.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1948.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1989.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2019), _2702, _2703, fa_mesh_fs_params[21].xyz, _2705, _2706, fa_mesh_fs_params[20].w, _2708, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    vec3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        vec3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / vec3(max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _267.xyz * atten, atten, 1.0, dist, _374);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _614;\n    if (i == 0)\n    {\n        _614 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _630;\n        if (i == 1)\n        {\n            _630 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _638;\n            if (i == 2)\n            {\n                _638 = fa_shadows[24].z;\n            }\n            else\n            {\n                _638 = fa_shadows[24].w;\n            }\n            _630 = _638;\n        }\n        _614 = _630;\n    }\n    return _614;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _671 = fa_shadow_depth(param, param_1);\n    float _675;\n    if (conv.x < 0.5)\n    {\n        _675 = _671;\n    }\n    else\n    {\n        _675 = (conv.y * conv.z) / (conv.z - (_671 * (conv.z - conv.y)));\n    }\n    return _675;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _602 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_602), sin(_602)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _721 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _735 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _721;\n            vec2 _754 = fa_shadow_vogel(param_3, param_4, param_5) * _735;\n            vec2 param_6 = uv + (_754 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _766 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_766 < (zr - (length(_754) * plane)))\n            {\n                sum += _766;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _810 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _810; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _810;\n        float param_11 = _721;\n        vec2 _829 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_829 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_829) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_810);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _871 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _876 = clamp(dot(n, l), 0.0, 1.0);\n    float _882 = sqrt(1.0 - (_876 * _876));\n    float _890 = min(_882 / max(_876, 0.20000000298023223876953125), 4.0);\n    float _895;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _895 = fa_shadows[26].y;\n    }\n    else\n    {\n        _895 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _920 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_895 * _882)), 1.0);\n    float _927 = _920.x;\n    bool _930 = _927 < fa_shadows[ci * 1 + 16].x;\n    bool _939;\n    if (!_930)\n    {\n        _939 = _927 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _939 = _930;\n    }\n    bool _948;\n    if (!_939)\n    {\n        _948 = _920.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _948 = _939;\n    }\n    bool _957;\n    if (!_948)\n    {\n        _957 = _920.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _957 = _948;\n    }\n    bool _964;\n    if (!_957)\n    {\n        _964 = _920.z > 1.0;\n    }\n    else\n    {\n        _964 = _957;\n    }\n    if (_964)\n    {\n        return -1.0;\n    }\n    float _973;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _973 = fa_shadows[26].x;\n    }\n    else\n    {\n        _973 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _920.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _920.z - ((_973 * (1.0 + (0.5 * _890))) / _871);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _871;\n    float param_5 = _871 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_890, 3.0)) * 0.5) / _871;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1367 = int(fa_shadows[25].x + 0.5);\n    if (_1367 < 1)\n    {\n        return 1.0;\n    }\n    float _1383 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1367 - 1;\n    if (_1383 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1395 = _1367 > 1;\n    bool _1402;\n    if (_1395)\n    {\n        _1402 = _1383 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1402 = _1395;\n    }\n    if (_1402)\n    {\n        ci = 1;\n    }\n    bool _1406 = _1367 > 2;\n    bool _1413;\n    if (_1406)\n    {\n        _1413 = _1383 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    if (_1413)\n    {\n        ci = 2;\n    }\n    bool _1417 = _1367 > 3;\n    bool _1424;\n    if (_1417)\n    {\n        _1424 = _1383 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1424 = _1417;\n    }\n    if (_1424)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1367)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1450 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1450;\n        if (_1450 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1475;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1475 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1475 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1494 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1475, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1505 = clamp((_1383 - (fa_shadow_split_at(param_7) - _1494)) / _1494, 0.0, 1.0);\n        if (_1505 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1367)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1526 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1526;\n                if (_1526 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1505);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1032 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1040;\n    if (!_1032)\n    {\n        _1040 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1040 = _1032;\n    }\n    if (_1040)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1053 = fa_light_texel(param);\n    float _1054 = _1053.x;\n    if (_1054 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1063 = int(_1054 + 0.5);\n    int param_1 = _1063;\n    vec4 _1067 = fa_light_texel(param_1);\n    int param_2 = _1063 + 1;\n    vec4 _1072 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1075 = _1067.y;\n    if (_1075 > 0.0)\n    {\n        float _1092 = 1.0 - smoothstep(0.75 * _1075, _1075, length(world - fa_shadows[27].xyz));\n        fade = _1092;\n        if (_1092 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1067.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1111 = world - fa_light_texel(param_3).xyz;\n        vec3 _1114 = abs(_1111);\n        float _1116 = _1114.x;\n        float _1118 = _1114.y;\n        bool _1119 = _1116 >= _1118;\n        bool _1127;\n        if (_1119)\n        {\n            _1127 = _1116 >= _1114.z;\n        }\n        else\n        {\n            _1127 = _1119;\n        }\n        int _1128;\n        if (_1127)\n        {\n            _1128 = (_1111.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1141;\n            if (_1118 >= _1114.z)\n            {\n                _1141 = (_1111.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1141 = (_1111.z > 0.0) ? 4 : 5;\n            }\n            _1128 = _1141;\n        }\n        face = _1128;\n    }\n    int _1160 = (_1063 + 2) + (face * 6);\n    int param_4 = _1160;\n    int param_5 = _1160 + 1;\n    int param_6 = _1160 + 3;\n    vec4 _1174 = fa_light_texel(param_6);\n    int param_7 = _1160 + 4;\n    vec4 _1179 = fa_light_texel(param_7);\n    int param_8 = _1160 + 5;\n    vec4 _1184 = fa_light_texel(param_8);\n    float _1196 = _1184.x * max(dot(_1174, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1201 = clamp(dot(n, l), 0.0, 1.0);\n    float _1207 = sqrt(1.0 - (_1201 * _1201));\n    float _1213 = min(_1207 / max(_1201, 0.20000000298023223876953125), 4.0);\n    float _1216 = _1072.y;\n    float _1218;\n    if (_1216 > 0.0)\n    {\n        _1218 = _1216;\n    }\n    else\n    {\n        _1218 = 1.5 * _1196;\n    }\n    vec4 _1238 = vec4(world + (n * (_1218 * _1207)), 1.0);\n    float _1242 = dot(_1174, _1238);\n    float _1245 = _1184.y;\n    if (_1242 < _1245)\n    {\n        return 1.0;\n    }\n    vec2 _1260 = vec2(dot(fa_light_texel(param_4), _1238), dot(fa_light_texel(param_5), _1238)) / vec2(_1242);\n    float _1262 = _1260.x;\n    bool _1265 = _1262 < _1179.x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1179.z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1260.y < _1179.y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1260.y > _1179.w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    if (_1292)\n    {\n        return 1.0;\n    }\n    float _1298 = _1072.x;\n    float _1300;\n    if (_1298 > 0.0)\n    {\n        _1300 = _1298;\n    }\n    else\n    {\n        _1300 = 1.5 * _1196;\n    }\n    vec2 param_9 = _1260;\n    vec4 param_10 = _1179;\n    float param_11 = _1242 - (_1300 * (1.0 + (0.5 * _1213)));\n    float param_12 = _1196;\n    float param_13 = 1.0;\n    float param_14 = _1184.z * 0.25;\n    float param_15 = (_1196 * min(_1213, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1245, _1184.z);\n    int param_17 = int(_1067.z + 0.5);\n    float param_18 = _1067.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1696 = fa_light_sample(param, param_1);\n    vec3 _2682 = _1696.direction;\n    vec3 _2677 = _1696.color;\n    float _2684 = _1696.attenuation;\n    float _2679 = _1696.shadow;\n    int _2687 = _1696.type;\n    if ((_2687 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2682;\n        float _1710 = fa_shadow_factor(param_2, param_3);\n        _2679 = _1710;\n        _2677 *= _1710;\n    }\n    else\n    {\n        bool _1721 = _2687 != 0;\n        bool _1727;\n        if (_1721)\n        {\n            _1727 = _2684 > 0.0;\n        }\n        else\n        {\n            _1727 = _1721;\n        }\n        if (_1727)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _2682;\n            float _1739 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2679 = _1739;\n            _2677 *= _1739;\n        }\n    }\n    return LightSample(_2682, _2677, _2684, _2679, _1696._distance, _2687);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1759;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1759 = 1.0;\n    }\n    else\n    {\n        _1759 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1759;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1550 = int(fa_shadows[25].x + 0.5);\n    float _1560 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1565 = _1550 > 0;\n    bool _1574;\n    if (_1565)\n    {\n        int param = _1550 - 1;\n        _1574 = _1560 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    if (_1574)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1581 = _1550 > 1;\n        bool _1588;\n        if (_1581)\n        {\n            _1588 = _1560 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1588 = _1581;\n        }\n        if (_1588)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1594 = _1550 > 2;\n        bool _1601;\n        if (_1594)\n        {\n            _1601 = _1560 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1601 = _1594;\n        }\n        if (_1601)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1607 = _1550 > 3;\n        bool _1614;\n        if (_1607)\n        {\n            _1614 = _1560 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1614 = _1607;\n        }\n        if (_1614)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2531 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2531 = -_2531;\n    }\n    vec3 _2144 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n    Surface _2152 = fa_standard_surface(param_1);\n    vec3 _2562 = _2152.albedo;\n    float _2563 = _2152.alpha;\n    vec3 _2564 = _2152.normal;\n    float _2565 = _2152.metallic;\n    float _2566 = _2152.roughness;\n    float _2567 = _2152.occlusion;\n    vec3 _2568 = _2152.emission;\n    float _2569 = _2152.clearcoat;\n    float _2570 = _2152.clearcoat_roughness;\n    vec3 _2571 = _2152.sheen_color;\n    float _2572 = _2152.sheen_roughness;\n    float _2573 = _2152.anisotropy;\n    float _2574 = _2152.anisotropy_rotation;\n    float _2575 = _2152.specular;\n    float _2576 = _2152.ior;\n    vec3 _2577 = _2152.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n    Surface param_3 = _2152;\n    surface(param_2, param_3);\n    _2562 = param_3.albedo;\n    _2563 = param_3.alpha;\n    _2564 = param_3.normal;\n    _2565 = param_3.metallic;\n    _2566 = param_3.roughness;\n    _2567 = param_3.occlusion;\n    _2568 = param_3.emission;\n    _2569 = param_3.clearcoat;\n    _2570 = param_3.clearcoat_roughness;\n    _2571 = param_3.sheen_color;\n    _2572 = param_3.sheen_roughness;\n    _2573 = param_3.anisotropy;\n    _2574 = param_3.anisotropy_rotation;\n    _2575 = param_3.specular;\n    _2576 = param_3.ior;\n    _2577 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2562;\n    }\n    else\n    {\n        vec3 _2173 = _2564;\n        vec3 _2174 = normalize(_2173);\n        _2564 = _2174;\n        vec3 param_4 = _2174;\n        vec3 lit = (fa_ambient_light(param_4) * _2562) * _2567;\n        int _2193 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2193; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2531;\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n            Surface param_10 = Surface(_2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570, _2571, _2572, _2573, _2574, _2575, _2576, _2577);\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _2230 = result;\n    vec3 _2231 = _2230 + _2568;\n    result = _2231;\n    vec3 param_12 = _2231;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2240 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2247;\n    if (!_2240)\n    {\n        _2247 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2247 = _2240;\n    }\n    if (_2247)\n    {\n        vec3 _2256 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2262 = dot(_2256, fa_mesh_fs_params[9].xyz);\n        bool _2266 = fa_mesh_fs_params[9].w > 0.5;\n        float _2267;\n        if (_2266)\n        {\n            _2267 = _2262;\n        }\n        else\n        {\n            _2267 = length(_2256);\n        }\n        float _2279 = _2267 - fa_mesh_fs_params[8].x;\n        if (_2279 > 0.0)\n        {\n            float _2288 = fa_mesh_fs_params[7].w * _2279;\n            float tau = _2288 * _2288;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2304;\n                if (_2266)\n                {\n                    _2304 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2262);\n                }\n                else\n                {\n                    _2304 = fa_mesh_fs_params[0].y;\n                }\n                float _2325 = mix(_2304, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2267, 0.0, 1.0));\n                float _2329 = fa_world_pos.y - _2325;\n                float _2334 = _2325 - fa_mesh_fs_params[8].z;\n                float _2339 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2342 = _2334 <= 0.0;\n                bool _2343 = !_2342;\n                bool _2349;\n                if (_2343)\n                {\n                    _2349 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2349 = _2342;\n                }\n                float _2350;\n                if (_2349)\n                {\n                    _2350 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2350 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2334, 80.0));\n                }\n                bool _2377;\n                if (_2343)\n                {\n                    _2377 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2377 = _2342;\n                }\n                float _2378;\n                if (_2377)\n                {\n                    _2378 = fa_mesh_fs_params[8].y * _2334;\n                }\n                else\n                {\n                    _2378 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2334, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2403 = _2339 <= 0.0;\n                bool _2410;\n                if (!_2403)\n                {\n                    _2410 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2410 = _2403;\n                }\n                float _2411;\n                if (_2410)\n                {\n                    _2411 = fa_mesh_fs_params[8].y * _2339;\n                }\n                else\n                {\n                    _2411 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2339, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2438;\n                if (abs(_2329) < 0.001000000047497451305389404296875)\n                {\n                    _2438 = _2350;\n                }\n                else\n                {\n                    _2438 = (_2411 - _2378) / _2329;\n                }\n                tau += (_2279 * max(_2438, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2563);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_388",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_624",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1765",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _393 = fa_mesh_fs_params[19].x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return ivec2(0);\n    }\n    vec4 _432 = vec4(world_pos, 1.0);\n    float _439 = dot(fa_mesh_fs_params[16], _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _461 = vec2(dot(fa_mesh_fs_params[14], _432), dot(fa_mesh_fs_params[15], _432)) / vec2(_439);\n    int _465 = int(fa_mesh_fs_params[18].x);\n    int _469 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _465 - 1);\n    vec4 _540 = fa_light_texel(param);\n    return ivec2(int(_540.x), int(_540.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1668 = fa_cluster_lookup(param);\n    fa_cl_slot = _1668.x;\n    fa_cl_local = _1668.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1825 = fa_linear_to_srgb(param);\n        c = _1825;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1833 = fa_srgb_to_linear(param_1);\n            c = _1833;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    vec3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    vec3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    vec3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1864 = fa_tex_fix(param_2, param_3);\n    vec4 _2782 = base_t;\n    _2782.x = _1864.x;\n    _2782.y = _1864.y;\n    _2782.z = _1864.z;\n    base_t = _2782;\n    vec4 _1878 = (_2782 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2697 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1910 = fa_tex_fix(param_6, param_7);\n        vec3 _1914 = (_1910 * 2.0) - vec3(1.0);\n        vec2 _1919 = _1914.xy * fa_mesh_fs_params[6].x;\n        vec3 _2790 = _1914;\n        _2790.x = _1919.x;\n        _2790.y = _1919.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2790;\n        _2697 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1948 = fa_tex_fix(param_12, param_13);\n    vec4 _2793 = mrt;\n    _2793.x = _1948.x;\n    _2793.y = _1948.y;\n    _2793.z = _1948.z;\n    mrt = _2793;\n    vec4 _1977 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1977.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1989 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2019 = fa_tex_fix(param_20, param_21);\n    float _2702 = fa_mesh_fs_params[20].x;\n    float _2703 = fa_mesh_fs_params[20].y;\n    float _2706 = fa_mesh_fs_params[20].z;\n    float _2705 = fa_mesh_fs_params[21].w;\n    float _2708 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2702 *= _1989.y;\n            _2703 *= _1989.z;\n            _2705 *= _1977.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2706 *= mrt.x;\n            _2708 *= mrt.w;\n        }\n    }\n    return Surface(_1878.xyz, _1878.w, _2697, clamp(fa_mesh_fs_params[5].x * _1948.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1948.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1989.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2019), _2702, _2703, fa_mesh_fs_params[21].xyz, _2705, _2706, fa_mesh_fs_params[20].w, _2708, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    vec3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        vec3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / vec3(max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _267.xyz * atten, atten, 1.0, dist, _374);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _614;\n    if (i == 0)\n    {\n        _614 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _630;\n        if (i == 1)\n        {\n            _630 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _638;\n            if (i == 2)\n            {\n                _638 = fa_shadows[24].z;\n            }\n            else\n            {\n                _638 = fa_shadows[24].w;\n            }\n            _630 = _638;\n        }\n        _614 = _630;\n    }\n    return _614;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _671 = fa_shadow_depth(param, param_1);\n    float _675;\n    if (conv.x < 0.5)\n    {\n        _675 = _671;\n    }\n    else\n    {\n        _675 = (conv.y * conv.z) / (conv.z - (_671 * (conv.z - conv.y)));\n    }\n    return _675;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _602 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_602), sin(_602)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _721 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _735 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _721;\n            vec2 _754 = fa_shadow_vogel(param_3, param_4, param_5) * _735;\n            vec2 param_6 = uv + (_754 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _766 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_766 < (zr - (length(_754) * plane)))\n            {\n                sum += _766;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _810 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _810; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _810;\n        float param_11 = _721;\n        vec2 _829 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_829 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_829) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_810);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _871 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _876 = clamp(dot(n, l), 0.0, 1.0);\n    float _882 = sqrt(1.0 - (_876 * _876));\n    float _890 = min(_882 / max(_876, 0.20000000298023223876953125), 4.0);\n    float _895;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _895 = fa_shadows[26].y;\n    }\n    else\n    {\n        _895 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _920 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_895 * _882)), 1.0);\n    float _927 = _920.x;\n    bool _930 = _927 < fa_shadows[ci * 1 + 16].x;\n    bool _939;\n    if (!_930)\n    {\n        _939 = _927 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _939 = _930;\n    }\n    bool _948;\n    if (!_939)\n    {\n        _948 = _920.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _948 = _939;\n    }\n    bool _957;\n    if (!_948)\n    {\n        _957 = _920.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _957 = _948;\n    }\n    bool _964;\n    if (!_957)\n    {\n        _964 = _920.z > 1.0;\n    }\n    else\n    {\n        _964 = _957;\n    }\n    if (_964)\n    {\n        return -1.0;\n    }\n    float _973;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _973 = fa_shadows[26].x;\n    }\n    else\n    {\n        _973 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _920.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _920.z - ((_973 * (1.0 + (0.5 * _890))) / _871);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _871;\n    float param_5 = _871 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_890, 3.0)) * 0.5) / _871;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1367 = int(fa_shadows[25].x + 0.5);\n    if (_1367 < 1)\n    {\n        return 1.0;\n    }\n    float _1383 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1367 - 1;\n    if (_1383 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1395 = _1367 > 1;\n    bool _1402;\n    if (_1395)\n    {\n        _1402 = _1383 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1402 = _1395;\n    }\n    if (_1402)\n    {\n        ci = 1;\n    }\n    bool _1406 = _1367 > 2;\n    bool _1413;\n    if (_1406)\n    {\n        _1413 = _1383 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1413 = _1406;\n    }\n    if (_1413)\n    {\n        ci = 2;\n    }\n    bool _1417 = _1367 > 3;\n    bool _1424;\n    if (_1417)\n    {\n        _1424 = _1383 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1424 = _1417;\n    }\n    if (_1424)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1367)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1450 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1450;\n        if (_1450 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1475;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1475 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1475 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1494 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1475, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1505 = clamp((_1383 - (fa_shadow_split_at(param_7) - _1494)) / _1494, 0.0, 1.0);\n        if (_1505 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1367)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1526 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1526;\n                if (_1526 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1505);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1032 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1040;\n    if (!_1032)\n    {\n        _1040 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1040 = _1032;\n    }\n    if (_1040)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1053 = fa_light_texel(param);\n    float _1054 = _1053.x;\n    if (_1054 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1063 = int(_1054 + 0.5);\n    int param_1 = _1063;\n    vec4 _1067 = fa_light_texel(param_1);\n    int param_2 = _1063 + 1;\n    vec4 _1072 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1075 = _1067.y;\n    if (_1075 > 0.0)\n    {\n        float _1092 = 1.0 - smoothstep(0.75 * _1075, _1075, length(world - fa_shadows[27].xyz));\n        fade = _1092;\n        if (_1092 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1067.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1111 = world - fa_light_texel(param_3).xyz;\n        vec3 _1114 = abs(_1111);\n        float _1116 = _1114.x;\n        float _1118 = _1114.y;\n        bool _1119 = _1116 >= _1118;\n        bool _1127;\n        if (_1119)\n        {\n            _1127 = _1116 >= _1114.z;\n        }\n        else\n        {\n            _1127 = _1119;\n        }\n        int _1128;\n        if (_1127)\n        {\n            _1128 = (_1111.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1141;\n            if (_1118 >= _1114.z)\n            {\n                _1141 = (_1111.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1141 = (_1111.z > 0.0) ? 4 : 5;\n            }\n            _1128 = _1141;\n        }\n        face = _1128;\n    }\n    int _1160 = (_1063 + 2) + (face * 6);\n    int param_4 = _1160;\n    int param_5 = _1160 + 1;\n    int param_6 = _1160 + 3;\n    vec4 _1174 = fa_light_texel(param_6);\n    int param_7 = _1160 + 4;\n    vec4 _1179 = fa_light_texel(param_7);\n    int param_8 = _1160 + 5;\n    vec4 _1184 = fa_light_texel(param_8);\n    float _1196 = _1184.x * max(dot(_1174, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1201 = clamp(dot(n, l), 0.0, 1.0);\n    float _1207 = sqrt(1.0 - (_1201 * _1201));\n    float _1213 = min(_1207 / max(_1201, 0.20000000298023223876953125), 4.0);\n    float _1216 = _1072.y;\n    float _1218;\n    if (_1216 > 0.0)\n    {\n        _1218 = _1216;\n    }\n    else\n    {\n        _1218 = 1.5 * _1196;\n    }\n    vec4 _1238 = vec4(world + (n * (_1218 * _1207)), 1.0);\n    float _1242 = dot(_1174, _1238);\n    float _1245 = _1184.y;\n    if (_1242 < _1245)\n    {\n        return 1.0;\n    }\n    vec2 _1260 = vec2(dot(fa_light_texel(param_4), _1238), dot(fa_light_texel(param_5), _1238)) / vec2(_1242);\n    float _1262 = _1260.x;\n    bool _1265 = _1262 < _1179.x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > _1179.z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1260.y < _1179.y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1260.y > _1179.w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    if (_1292)\n    {\n        return 1.0;\n    }\n    float _1298 = _1072.x;\n    float _1300;\n    if (_1298 > 0.0)\n    {\n        _1300 = _1298;\n    }\n    else\n    {\n        _1300 = 1.5 * _1196;\n    }\n    vec2 param_9 = _1260;\n    vec4 param_10 = _1179;\n    float param_11 = _1242 - (_1300 * (1.0 + (0.5 * _1213)));\n    float param_12 = _1196;\n    float param_13 = 1.0;\n    float param_14 = _1184.z * 0.25;\n    float param_15 = (_1196 * min(_1213, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1245, _1184.z);\n    int param_17 = int(_1067.z + 0.5);\n    float param_18 = _1067.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1696 = fa_light_sample(param, param_1);\n    vec3 _2682 = _1696.direction;\n    vec3 _2677 = _1696.color;\n    float _2684 = _1696.attenuation;\n    float _2679 = _1696.shadow;\n    int _2687 = _1696.type;\n    if ((_2687 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2682;\n        float _1710 = fa_shadow_factor(param_2, param_3);\n        _2679 = _1710;\n        _2677 *= _1710;\n    }\n    else\n    {\n        bool _1721 = _2687 != 0;\n        bool _1727;\n        if (_1721)\n        {\n            _1727 = _2684 > 0.0;\n        }\n        else\n        {\n            _1727 = _1721;\n        }\n        if (_1727)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _2682;\n            float _1739 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2679 = _1739;\n            _2677 *= _1739;\n        }\n    }\n    return LightSample(_2682, _2677, _2684, _2679, _1696._distance, _2687);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1759;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1759 = 1.0;\n    }\n    else\n    {\n        _1759 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1759;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1550 = int(fa_shadows[25].x + 0.5);\n    float _1560 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1565 = _1550 > 0;\n    bool _1574;\n    if (_1565)\n    {\n        int param = _1550 - 1;\n        _1574 = _1560 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1574 = _1565;\n    }\n    if (_1574)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1581 = _1550 > 1;\n        bool _1588;\n        if (_1581)\n        {\n            _1588 = _1560 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1588 = _1581;\n        }\n        if (_1588)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1594 = _1550 > 2;\n        bool _1601;\n        if (_1594)\n        {\n            _1601 = _1560 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1601 = _1594;\n        }\n        if (_1601)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1607 = _1550 > 3;\n        bool _1614;\n        if (_1607)\n        {\n            _1614 = _1560 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1614 = _1607;\n        }\n        if (_1614)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2531 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2531 = -_2531;\n    }\n    vec3 _2144 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n    Surface _2152 = fa_standard_surface(param_1);\n    vec3 _2562 = _2152.albedo;\n    float _2563 = _2152.alpha;\n    vec3 _2564 = _2152.normal;\n    float _2565 = _2152.metallic;\n    float _2566 = _2152.roughness;\n    float _2567 = _2152.occlusion;\n    vec3 _2568 = _2152.emission;\n    float _2569 = _2152.clearcoat;\n    float _2570 = _2152.clearcoat_roughness;\n    vec3 _2571 = _2152.sheen_color;\n    float _2572 = _2152.sheen_roughness;\n    float _2573 = _2152.anisotropy;\n    float _2574 = _2152.anisotropy_rotation;\n    float _2575 = _2152.specular;\n    float _2576 = _2152.ior;\n    vec3 _2577 = _2152.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n    Surface param_3 = _2152;\n    surface(param_2, param_3);\n    _2562 = param_3.albedo;\n    _2563 = param_3.alpha;\n    _2564 = param_3.normal;\n    _2565 = param_3.metallic;\n    _2566 = param_3.roughness;\n    _2567 = param_3.occlusion;\n    _2568 = param_3.emission;\n    _2569 = param_3.clearcoat;\n    _2570 = param_3.clearcoat_roughness;\n    _2571 = param_3.sheen_color;\n    _2572 = param_3.sheen_roughness;\n    _2573 = param_3.anisotropy;\n    _2574 = param_3.anisotropy_rotation;\n    _2575 = param_3.specular;\n    _2576 = param_3.ior;\n    _2577 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2562;\n    }\n    else\n    {\n        vec3 _2173 = _2564;\n        vec3 _2174 = normalize(_2173);\n        _2564 = _2174;\n        vec3 param_4 = _2174;\n        vec3 lit = (fa_ambient_light(param_4) * _2562) * _2567;\n        int _2193 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2193; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2531;\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2531, fa_world_tangent, fa_uv, fa_vertex_color, _2144, gl_FrontFacing);\n            Surface param_10 = Surface(_2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570, _2571, _2572, _2573, _2574, _2575, _2576, _2577);\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _2230 = result;\n    vec3 _2231 = _2230 + _2568;\n    result = _2231;\n    vec3 param_12 = _2231;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _2240 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2247;\n    if (!_2240)\n    {\n        _2247 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2247 = _2240;\n    }\n    if (_2247)\n    {\n        vec3 _2256 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2262 = dot(_2256, fa_mesh_fs_params[9].xyz);\n        bool _2266 = fa_mesh_fs_params[9].w > 0.5;\n        float _2267;\n        if (_2266)\n        {\n            _2267 = _2262;\n        }\n        else\n        {\n            _2267 = length(_2256);\n        }\n        float _2279 = _2267 - fa_mesh_fs_params[8].x;\n        if (_2279 > 0.0)\n        {\n            float _2288 = fa_mesh_fs_params[7].w * _2279;\n            float tau = _2288 * _2288;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2304;\n                if (_2266)\n                {\n                    _2304 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2262);\n                }\n                else\n                {\n                    _2304 = fa_mesh_fs_params[0].y;\n                }\n                float _2325 = mix(_2304, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2267, 0.0, 1.0));\n                float _2329 = fa_world_pos.y - _2325;\n                float _2334 = _2325 - fa_mesh_fs_params[8].z;\n                float _2339 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2342 = _2334 <= 0.0;\n                bool _2343 = !_2342;\n                bool _2349;\n                if (_2343)\n                {\n                    _2349 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2349 = _2342;\n                }\n                float _2350;\n                if (_2349)\n                {\n                    _2350 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2350 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2334, 80.0));\n                }\n                bool _2377;\n                if (_2343)\n                {\n                    _2377 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2377 = _2342;\n                }\n                float _2378;\n                if (_2377)\n                {\n                    _2378 = fa_mesh_fs_params[8].y * _2334;\n                }\n                else\n                {\n                    _2378 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2334, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2403 = _2339 <= 0.0;\n                bool _2410;\n                if (!_2403)\n                {\n                    _2410 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2410 = _2403;\n                }\n                float _2411;\n                if (_2410)\n                {\n                    _2411 = fa_mesh_fs_params[8].y * _2339;\n                }\n                else\n                {\n                    _2411 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2339, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2438;\n                if (abs(_2329) < 0.001000000047497451305389404296875)\n                {\n                    _2438 = _2350;\n                }\n                else\n                {\n                    _2438 = (_2411 - _2378) / _2329;\n                }\n                tau += (_2279 * max(_2438, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2563);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_388",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_624",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1765",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    vec4 _241 = (_786 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _749 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = fa_mesh_fs_params[20].x;\n    float _755 = fa_mesh_fs_params[20].y;\n    float _758 = fa_mesh_fs_params[20].z;\n    float _757 = fa_mesh_fs_params[21].w;\n    float _760 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _749, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _754, _755, fa_mesh_fs_params[21].xyz, _757, _758, fa_mesh_fs_params[20].w, _760, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    vec4 _241 = (_786 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _749 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = fa_mesh_fs_params[20].x;\n    float _755 = fa_mesh_fs_params[20].y;\n    float _758 = fa_mesh_fs_params[20].z;\n    float _757 = fa_mesh_fs_params[21].w;\n    float _760 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _749, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _754, _755, fa_mesh_fs_params[21].xyz, _757, _758, fa_mesh_fs_params[20].w, _760, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
