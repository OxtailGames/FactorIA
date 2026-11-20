{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _368 = fa_mesh_fs_params[19].x < 0.0;\n    bool _375;\n    if (!_368)\n    {\n        _375 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return ivec2(0);\n    }\n    vec4 _407 = vec4(world_pos, 1.0);\n    float _414 = dot(fa_mesh_fs_params[16], _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _436 = vec2(dot(fa_mesh_fs_params[14], _407), dot(fa_mesh_fs_params[15], _407)) / vec2(_414);\n    int _440 = int(fa_mesh_fs_params[18].x);\n    int _444 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _440 - 1);\n    vec4 _515 = fa_light_texel(param);\n    return ivec2(int(_515.x), int(_515.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1260 = fa_cluster_lookup(param);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1363 = fa_linear_to_srgb(param);\n        c = _1363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1371 = fa_srgb_to_linear(param_1);\n            c = _1371;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _144;\n    if (i.front_facing)\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    vec3 _168 = normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    vec3 _196 = normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    vec3 _199;\n    if (i.front_facing)\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1402 = fa_tex_fix(param_2, param_3);\n    vec4 _2289 = base_t;\n    _2289.x = _1402.x;\n    _2289.y = _1402.y;\n    _2289.z = _1402.z;\n    base_t = _2289;\n    vec4 _1416 = (_2289 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2236 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1448 = fa_tex_fix(param_6, param_7);\n        vec3 _1452 = (_1448 * 2.0) - vec3(1.0);\n        vec2 _1457 = _1452.xy * fa_mesh_fs_params[6].x;\n        vec3 _2297 = _1452;\n        _2297.x = _1457.x;\n        _2297.y = _1457.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2297;\n        _2236 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1486 = fa_tex_fix(param_12, param_13);\n    vec4 _2300 = mrt;\n    _2300.x = _1486.x;\n    _2300.y = _1486.y;\n    _2300.z = _1486.z;\n    mrt = _2300;\n    vec4 _1515 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1515.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1527 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1557 = fa_tex_fix(param_20, param_21);\n    float _2241 = fa_mesh_fs_params[20].x;\n    float _2242 = fa_mesh_fs_params[20].y;\n    float _2245 = fa_mesh_fs_params[20].z;\n    float _2244 = fa_mesh_fs_params[21].w;\n    float _2247 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2241 *= _1527.y;\n            _2242 *= _1527.z;\n            _2244 *= _1515.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2245 *= mrt.x;\n            _2247 *= mrt.w;\n        }\n    }\n    return Surface(_1416.xyz, _1416.w, _2236, clamp(fa_mesh_fs_params[5].x * _1486.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1486.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1527.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1557), _2241, _2242, fa_mesh_fs_params[21].xyz, _2244, _2245, fa_mesh_fs_params[20].w, _2247, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _236 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _242 = fa_light_texel(param_1);\n    float _245 = _242.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _252 = _245 < 0.5;\n    vec3 l;\n    if (_252)\n    {\n        l = normalize(_236.xyz);\n    }\n    else\n    {\n        vec3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / vec3(max(_266, 9.9999997473787516355514526367188e-05));\n        float _281 = _266 / max(_236.w, 0.001000000047497451305389404296875);\n        float _287 = clamp(1.0 - (_281 * _281), 0.0, 1.0);\n        atten = _287 * _287;\n        if (_245 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _301 = fa_light_texel(param_2);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _318 = fa_light_texel(param_3);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5)\n            {\n                cos_inner = mix(_311, 1.0, 0.25);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _242.xyz * atten, atten, 1.0, dist, _349);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = fa_shadows[24].z;\n            }\n            else\n            {\n                _613 = fa_shadows[24].w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _651 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _656 = clamp(dot(n, l), 0.0, 1.0);\n    float _662 = sqrt(1.0 - (_656 * _656));\n    float _670 = min(_662 / max(_656, 0.20000000298023223876953125), 4.0);\n    float _675;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _675 = fa_shadows[26].y;\n    }\n    else\n    {\n        _675 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _700 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_675 * _662)), 1.0);\n    float _707 = _700.x;\n    bool _710 = _707 < fa_shadows[ci * 1 + 16].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0;\n    }\n    float _753;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _753 = fa_shadows[26].x;\n    }\n    else\n    {\n        _753 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0 + (0.5 * _670))) / _651);\n    float _781 = ((fa_shadows[ci * 1 + 20].x * min(_670, 3.0)) * 0.5) / _651;\n    int _790 = int(fa_shadows[25].z + 0.5);\n    if (_790 == 1)\n    {\n        vec2 param = _700.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _801 = fa_shadow_depth(param, param_1);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = clamp(((fa_shadows[25].w * _651) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            vec2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            vec2 param_5 = _700.xy + (_844 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _855 = fa_shadow_depth(param_5, param_6);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_772 - (sum / cnt), 0.0) * _651) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        vec2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _700.xy + (_918 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _929 = fa_shadow_depth(param_10, param_11);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _959 = int(fa_shadows[25].x + 0.5);\n    if (_959 < 1)\n    {\n        return 1.0;\n    }\n    float _975 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > fa_shadows[24].x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1042;\n        if (_1042 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1067 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1086 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1067, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1097 = clamp((_975 - (fa_shadow_split_at(param_7) - _1086)) / _1086, 0.0, 1.0);\n        if (_1097 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1118;\n                if (_1118 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1);\n    vec3 _2221 = _1288.direction;\n    vec3 _2216 = _1288.color;\n    float _2218 = _1288.shadow;\n    int _2226 = _1288.type;\n    if ((_2226 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2221;\n        float _1302 = fa_shadow_factor(param_2, param_3);\n        _2218 = _1302;\n        _2216 *= _1302;\n    }\n    return LightSample(_2221, _2216, _1288.attenuation, _2218, _1288._distance, _2226);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1142 = int(fa_shadows[25].x + 0.5);\n    float _1152 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2070 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2070 = -_2070;\n    }\n    vec3 _1683 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n    Surface _1691 = fa_standard_surface(param_1);\n    vec3 _2101 = _1691.albedo;\n    float _2102 = _1691.alpha;\n    vec3 _2103 = _1691.normal;\n    float _2104 = _1691.metallic;\n    float _2105 = _1691.roughness;\n    float _2106 = _1691.occlusion;\n    vec3 _2107 = _1691.emission;\n    float _2108 = _1691.clearcoat;\n    float _2109 = _1691.clearcoat_roughness;\n    vec3 _2110 = _1691.sheen_color;\n    float _2111 = _1691.sheen_roughness;\n    float _2112 = _1691.anisotropy;\n    float _2113 = _1691.anisotropy_rotation;\n    float _2114 = _1691.specular;\n    float _2115 = _1691.ior;\n    vec3 _2116 = _1691.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n    Surface param_3 = _1691;\n    surface(param_2, param_3);\n    _2101 = param_3.albedo;\n    _2102 = param_3.alpha;\n    _2103 = param_3.normal;\n    _2104 = param_3.metallic;\n    _2105 = param_3.roughness;\n    _2106 = param_3.occlusion;\n    _2107 = param_3.emission;\n    _2108 = param_3.clearcoat;\n    _2109 = param_3.clearcoat_roughness;\n    _2110 = param_3.sheen_color;\n    _2111 = param_3.sheen_roughness;\n    _2112 = param_3.anisotropy;\n    _2113 = param_3.anisotropy_rotation;\n    _2114 = param_3.specular;\n    _2115 = param_3.ior;\n    _2116 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2101;\n    }\n    else\n    {\n        vec3 _1712 = _2103;\n        vec3 _1713 = normalize(_1712);\n        _2103 = _1713;\n        vec3 param_4 = _1713;\n        vec3 lit = (fa_ambient_light(param_4) * _2101) * _2106;\n        int _1732 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1732; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2070;\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n            Surface param_10 = Surface(_2101, _2102, _2103, _2104, _2105, _2106, _2107, _2108, _2109, _2110, _2111, _2112, _2113, _2114, _2115, _2116);\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _1769 = result;\n    vec3 _1770 = _1769 + _2107;\n    result = _1770;\n    vec3 param_12 = _1770;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _1779 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1786;\n    if (!_1779)\n    {\n        _1786 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1786 = _1779;\n    }\n    if (_1786)\n    {\n        vec3 _1795 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1801 = dot(_1795, fa_mesh_fs_params[9].xyz);\n        bool _1805 = fa_mesh_fs_params[9].w > 0.5;\n        float _1806;\n        if (_1805)\n        {\n            _1806 = _1801;\n        }\n        else\n        {\n            _1806 = length(_1795);\n        }\n        float _1818 = _1806 - fa_mesh_fs_params[8].x;\n        if (_1818 > 0.0)\n        {\n            float _1827 = fa_mesh_fs_params[7].w * _1818;\n            float tau = _1827 * _1827;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1843;\n                if (_1805)\n                {\n                    _1843 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1801);\n                }\n                else\n                {\n                    _1843 = fa_mesh_fs_params[0].y;\n                }\n                float _1864 = mix(_1843, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1806, 0.0, 1.0));\n                float _1868 = fa_world_pos.y - _1864;\n                float _1873 = _1864 - fa_mesh_fs_params[8].z;\n                float _1878 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1881 = _1873 <= 0.0;\n                bool _1882 = !_1881;\n                bool _1888;\n                if (_1882)\n                {\n                    _1888 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1881;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1889 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1873, 80.0));\n                }\n                bool _1916;\n                if (_1882)\n                {\n                    _1916 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1916 = _1881;\n                }\n                float _1917;\n                if (_1916)\n                {\n                    _1917 = fa_mesh_fs_params[8].y * _1873;\n                }\n                else\n                {\n                    _1917 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1873, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1942 = _1878 <= 0.0;\n                bool _1949;\n                if (!_1942)\n                {\n                    _1949 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1949 = _1942;\n                }\n                float _1950;\n                if (_1949)\n                {\n                    _1950 = fa_mesh_fs_params[8].y * _1878;\n                }\n                else\n                {\n                    _1950 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1878, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1977;\n                if (abs(_1868) < 0.001000000047497451305389404296875)\n                {\n                    _1977 = _1889;\n                }\n                else\n                {\n                    _1977 = (_1950 - _1917) / _1868;\n                }\n                tau += (_1818 * max(_1977, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2102);\n}\n\n",
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
            "inst_name": "_363",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _368 = fa_mesh_fs_params[19].x < 0.0;\n    bool _375;\n    if (!_368)\n    {\n        _375 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _375 = _368;\n    }\n    bool _383;\n    if (!_375)\n    {\n        _383 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _383 = _375;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    if (_397)\n    {\n        return ivec2(0);\n    }\n    vec4 _407 = vec4(world_pos, 1.0);\n    float _414 = dot(fa_mesh_fs_params[16], _407);\n    if (!(_414 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _436 = vec2(dot(fa_mesh_fs_params[14], _407), dot(fa_mesh_fs_params[15], _407)) / vec2(_414);\n    int _440 = int(fa_mesh_fs_params[18].x);\n    int _444 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _444) + clamp(int(floor(((_436.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _444 - 1)) * _440)) + clamp(int(floor(((_436.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _440 - 1);\n    vec4 _515 = fa_light_texel(param);\n    return ivec2(int(_515.x), int(_515.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1260 = fa_cluster_lookup(param);\n    fa_cl_slot = _1260.x;\n    fa_cl_local = _1260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1363 = fa_linear_to_srgb(param);\n        c = _1363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1371 = fa_srgb_to_linear(param_1);\n            c = _1371;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _144;\n    if (i.front_facing)\n    {\n        _144 = i.world_normal;\n    }\n    else\n    {\n        _144 = -i.world_normal;\n    }\n    vec3 _168 = normalize(i.world_tangent.xyz - (_144 * dot(_144, i.world_tangent.xyz)));\n    vec3 _196 = normalize(((_168 * m.x) + ((cross(_144, _168) * i.world_tangent.w) * m.y)) + (_144 * m.z));\n    vec3 _199;\n    if (i.front_facing)\n    {\n        _199 = _196;\n    }\n    else\n    {\n        _199 = -_196;\n    }\n    return _199;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1402 = fa_tex_fix(param_2, param_3);\n    vec4 _2289 = base_t;\n    _2289.x = _1402.x;\n    _2289.y = _1402.y;\n    _2289.z = _1402.z;\n    base_t = _2289;\n    vec4 _1416 = (_2289 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2236 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1448 = fa_tex_fix(param_6, param_7);\n        vec3 _1452 = (_1448 * 2.0) - vec3(1.0);\n        vec2 _1457 = _1452.xy * fa_mesh_fs_params[6].x;\n        vec3 _2297 = _1452;\n        _2297.x = _1457.x;\n        _2297.y = _1457.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2297;\n        _2236 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1486 = fa_tex_fix(param_12, param_13);\n    vec4 _2300 = mrt;\n    _2300.x = _1486.x;\n    _2300.y = _1486.y;\n    _2300.z = _1486.z;\n    mrt = _2300;\n    vec4 _1515 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1515.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1527 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1557 = fa_tex_fix(param_20, param_21);\n    float _2241 = fa_mesh_fs_params[20].x;\n    float _2242 = fa_mesh_fs_params[20].y;\n    float _2245 = fa_mesh_fs_params[20].z;\n    float _2244 = fa_mesh_fs_params[21].w;\n    float _2247 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2241 *= _1527.y;\n            _2242 *= _1527.z;\n            _2244 *= _1515.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2245 *= mrt.x;\n            _2247 *= mrt.w;\n        }\n    }\n    return Surface(_1416.xyz, _1416.w, _2236, clamp(fa_mesh_fs_params[5].x * _1486.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1486.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1527.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1557), _2241, _2242, fa_mesh_fs_params[21].xyz, _2244, _2245, fa_mesh_fs_params[20].w, _2247, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _236 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _242 = fa_light_texel(param_1);\n    float _245 = _242.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _252 = _245 < 0.5;\n    vec3 l;\n    if (_252)\n    {\n        l = normalize(_236.xyz);\n    }\n    else\n    {\n        vec3 _264 = _236.xyz - world_pos;\n        float _266 = length(_264);\n        dist = _266;\n        l = _264 / vec3(max(_266, 9.9999997473787516355514526367188e-05));\n        float _281 = _266 / max(_236.w, 0.001000000047497451305389404296875);\n        float _287 = clamp(1.0 - (_281 * _281), 0.0, 1.0);\n        atten = _287 * _287;\n        if (_245 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _301 = fa_light_texel(param_2);\n            float _311 = _301.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _318 = fa_light_texel(param_3);\n            float _319 = _318.x;\n            float cos_inner = _319;\n            if (_319 > 1.5)\n            {\n                cos_inner = mix(_311, 1.0, 0.25);\n            }\n            atten *= smoothstep(_311, cos_inner, dot(-l, normalize(_301.xyz)));\n        }\n    }\n    int _349;\n    if (_252)\n    {\n        _349 = 0;\n    }\n    else\n    {\n        _349 = (_245 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _242.xyz * atten, atten, 1.0, dist, _349);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _589;\n    if (i == 0)\n    {\n        _589 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _605;\n        if (i == 1)\n        {\n            _605 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _613;\n            if (i == 2)\n            {\n                _613 = fa_shadows[24].z;\n            }\n            else\n            {\n                _613 = fa_shadows[24].w;\n            }\n            _605 = _613;\n        }\n        _589 = _605;\n    }\n    return _589;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _577 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_577), sin(_577)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _651 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _656 = clamp(dot(n, l), 0.0, 1.0);\n    float _662 = sqrt(1.0 - (_656 * _656));\n    float _670 = min(_662 / max(_656, 0.20000000298023223876953125), 4.0);\n    float _675;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _675 = fa_shadows[26].y;\n    }\n    else\n    {\n        _675 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _700 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_675 * _662)), 1.0);\n    float _707 = _700.x;\n    bool _710 = _707 < fa_shadows[ci * 1 + 16].x;\n    bool _719;\n    if (!_710)\n    {\n        _719 = _707 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _719 = _710;\n    }\n    bool _728;\n    if (!_719)\n    {\n        _728 = _700.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _728 = _719;\n    }\n    bool _737;\n    if (!_728)\n    {\n        _737 = _700.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _737 = _728;\n    }\n    bool _744;\n    if (!_737)\n    {\n        _744 = _700.z > 1.0;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return -1.0;\n    }\n    float _753;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _753 = fa_shadows[26].x;\n    }\n    else\n    {\n        _753 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _772 = _700.z - ((_753 * (1.0 + (0.5 * _670))) / _651);\n    float _781 = ((fa_shadows[ci * 1 + 20].x * min(_670, 3.0)) * 0.5) / _651;\n    int _790 = int(fa_shadows[25].z + 0.5);\n    if (_790 == 1)\n    {\n        vec2 param = _700.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _801 = fa_shadow_depth(param, param_1);\n        return float(_772 <= _801);\n    }\n    float _808 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _811 = _790 == 2;\n    if (_811)\n    {\n        float _825 = clamp(((fa_shadows[25].w * _651) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _808;\n            vec2 _844 = fa_shadow_vogel(param_2, param_3, param_4) * _825;\n            vec2 param_5 = _700.xy + (_844 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _855 = fa_shadow_depth(param_5, param_6);\n            if (_855 < (_772 - (length(_844) * _781)))\n            {\n                sum += _855;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_772 - (sum / cnt), 0.0) * _651) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _899 = _811 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _899; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _899;\n        float param_9 = _808;\n        vec2 _918 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _700.xy + (_918 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _929 = fa_shadow_depth(param_10, param_11);\n        lit += float((_772 - (length(_918) * _781)) <= _929);\n    }\n    return lit / float(_899);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _959 = int(fa_shadows[25].x + 0.5);\n    if (_959 < 1)\n    {\n        return 1.0;\n    }\n    float _975 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _959 - 1;\n    if (_975 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _987 = _959 > 1;\n    bool _994;\n    if (_987)\n    {\n        _994 = _975 > fa_shadows[24].x;\n    }\n    else\n    {\n        _994 = _987;\n    }\n    if (_994)\n    {\n        ci = 1;\n    }\n    bool _998 = _959 > 2;\n    bool _1005;\n    if (_998)\n    {\n        _1005 = _975 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1005 = _998;\n    }\n    if (_1005)\n    {\n        ci = 2;\n    }\n    bool _1009 = _959 > 3;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _975 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _959)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1042 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1042;\n        if (_1042 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1067;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1067 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1067 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1086 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1067, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1097 = clamp((_975 - (fa_shadow_split_at(param_7) - _1086)) / _1086, 0.0, 1.0);\n        if (_1097 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _959)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1118 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1118;\n                if (_1118 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1097);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1288 = fa_light_sample(param, param_1);\n    vec3 _2221 = _1288.direction;\n    vec3 _2216 = _1288.color;\n    float _2218 = _1288.shadow;\n    int _2226 = _1288.type;\n    if ((_2226 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2221;\n        float _1302 = fa_shadow_factor(param_2, param_3);\n        _2218 = _1302;\n        _2216 *= _1302;\n    }\n    return LightSample(_2221, _2216, _1288.attenuation, _2218, _1288._distance, _2226);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1142 = int(fa_shadows[25].x + 0.5);\n    float _1152 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1157 = _1142 > 0;\n    bool _1166;\n    if (_1157)\n    {\n        int param = _1142 - 1;\n        _1166 = _1152 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1166 = _1157;\n    }\n    if (_1166)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1173 = _1142 > 1;\n        bool _1180;\n        if (_1173)\n        {\n            _1180 = _1152 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1180 = _1173;\n        }\n        if (_1180)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1186 = _1142 > 2;\n        bool _1193;\n        if (_1186)\n        {\n            _1193 = _1152 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1193 = _1186;\n        }\n        if (_1193)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1199 = _1142 > 3;\n        bool _1206;\n        if (_1199)\n        {\n            _1206 = _1152 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1206 = _1199;\n        }\n        if (_1206)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2070 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2070 = -_2070;\n    }\n    vec3 _1683 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n    Surface _1691 = fa_standard_surface(param_1);\n    vec3 _2101 = _1691.albedo;\n    float _2102 = _1691.alpha;\n    vec3 _2103 = _1691.normal;\n    float _2104 = _1691.metallic;\n    float _2105 = _1691.roughness;\n    float _2106 = _1691.occlusion;\n    vec3 _2107 = _1691.emission;\n    float _2108 = _1691.clearcoat;\n    float _2109 = _1691.clearcoat_roughness;\n    vec3 _2110 = _1691.sheen_color;\n    float _2111 = _1691.sheen_roughness;\n    float _2112 = _1691.anisotropy;\n    float _2113 = _1691.anisotropy_rotation;\n    float _2114 = _1691.specular;\n    float _2115 = _1691.ior;\n    vec3 _2116 = _1691.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n    Surface param_3 = _1691;\n    surface(param_2, param_3);\n    _2101 = param_3.albedo;\n    _2102 = param_3.alpha;\n    _2103 = param_3.normal;\n    _2104 = param_3.metallic;\n    _2105 = param_3.roughness;\n    _2106 = param_3.occlusion;\n    _2107 = param_3.emission;\n    _2108 = param_3.clearcoat;\n    _2109 = param_3.clearcoat_roughness;\n    _2110 = param_3.sheen_color;\n    _2111 = param_3.sheen_roughness;\n    _2112 = param_3.anisotropy;\n    _2113 = param_3.anisotropy_rotation;\n    _2114 = param_3.specular;\n    _2115 = param_3.ior;\n    _2116 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2101;\n    }\n    else\n    {\n        vec3 _1712 = _2103;\n        vec3 _1713 = normalize(_1712);\n        _2103 = _1713;\n        vec3 param_4 = _1713;\n        vec3 lit = (fa_ambient_light(param_4) * _2101) * _2106;\n        int _1732 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1732; ln++)\n        {\n            int param_5 = ln;\n            int param_6 = fa_cl_light(param_5);\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2070;\n            SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2070, fa_world_tangent, fa_uv, fa_vertex_color, _1683, gl_FrontFacing);\n            Surface param_10 = Surface(_2101, _2102, _2103, _2104, _2105, _2106, _2107, _2108, _2109, _2110, _2111, _2112, _2113, _2114, _2115, _2116);\n            LightSample param_11 = fa_light_shadowed(param_6, param_7, param_8);\n            lit += light(param_9, param_10, param_11);\n        }\n        result = lit;\n    }\n    vec3 _1769 = result;\n    vec3 _1770 = _1769 + _2107;\n    result = _1770;\n    vec3 param_12 = _1770;\n    vec3 param_13 = fa_world_pos;\n    result = fa_shadow_debug(param_12, param_13);\n    bool _1779 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1786;\n    if (!_1779)\n    {\n        _1786 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1786 = _1779;\n    }\n    if (_1786)\n    {\n        vec3 _1795 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1801 = dot(_1795, fa_mesh_fs_params[9].xyz);\n        bool _1805 = fa_mesh_fs_params[9].w > 0.5;\n        float _1806;\n        if (_1805)\n        {\n            _1806 = _1801;\n        }\n        else\n        {\n            _1806 = length(_1795);\n        }\n        float _1818 = _1806 - fa_mesh_fs_params[8].x;\n        if (_1818 > 0.0)\n        {\n            float _1827 = fa_mesh_fs_params[7].w * _1818;\n            float tau = _1827 * _1827;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1843;\n                if (_1805)\n                {\n                    _1843 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1801);\n                }\n                else\n                {\n                    _1843 = fa_mesh_fs_params[0].y;\n                }\n                float _1864 = mix(_1843, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1806, 0.0, 1.0));\n                float _1868 = fa_world_pos.y - _1864;\n                float _1873 = _1864 - fa_mesh_fs_params[8].z;\n                float _1878 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1881 = _1873 <= 0.0;\n                bool _1882 = !_1881;\n                bool _1888;\n                if (_1882)\n                {\n                    _1888 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1881;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1889 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1873, 80.0));\n                }\n                bool _1916;\n                if (_1882)\n                {\n                    _1916 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1916 = _1881;\n                }\n                float _1917;\n                if (_1916)\n                {\n                    _1917 = fa_mesh_fs_params[8].y * _1873;\n                }\n                else\n                {\n                    _1917 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1873, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1942 = _1878 <= 0.0;\n                bool _1949;\n                if (!_1942)\n                {\n                    _1949 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1949 = _1942;\n                }\n                float _1950;\n                if (_1949)\n                {\n                    _1950 = fa_mesh_fs_params[8].y * _1878;\n                }\n                else\n                {\n                    _1950 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1878, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1977;\n                if (abs(_1868) < 0.001000000047497451305389404296875)\n                {\n                    _1977 = _1889;\n                }\n                else\n                {\n                    _1977 = (_1950 - _1917) / _1868;\n                }\n                tau += (_1818 * max(_1977, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2102);\n}\n\n",
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
            "inst_name": "_363",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_599",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
