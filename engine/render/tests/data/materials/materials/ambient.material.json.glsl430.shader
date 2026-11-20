{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _401 = fa_mesh_fs_params[19].x < 0.0;\n    bool _408;\n    if (!_401)\n    {\n        _408 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _408 = _401;\n    }\n    bool _416;\n    if (!_408)\n    {\n        _416 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _416 = _408;\n    }\n    bool _423;\n    if (!_416)\n    {\n        _423 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _423 = _416;\n    }\n    bool _430;\n    if (!_423)\n    {\n        _430 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    if (_430)\n    {\n        return ivec2(0);\n    }\n    vec4 _440 = vec4(world_pos, 1.0);\n    float _447 = dot(fa_mesh_fs_params[16], _440);\n    if (!(_447 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _469 = vec2(dot(fa_mesh_fs_params[14], _440), dot(fa_mesh_fs_params[15], _440)) / vec2(_447);\n    int _473 = int(fa_mesh_fs_params[18].x);\n    int _477 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _477) + clamp(int(floor(((_469.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _477 - 1)) * _473)) + clamp(int(floor(((_469.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _473 - 1);\n    vec4 _548 = fa_light_texel(param);\n    return ivec2(int(_548.x), int(_548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1293 = fa_cluster_lookup(param);\n    fa_cl_slot = _1293.x;\n    fa_cl_local = _1293.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1429 = fa_linear_to_srgb(param);\n        c = _1429;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1437 = fa_srgb_to_linear(param_1);\n            c = _1437;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _160;\n    if (i.front_facing)\n    {\n        _160 = i.world_normal;\n    }\n    else\n    {\n        _160 = -i.world_normal;\n    }\n    vec3 _184 = normalize(i.world_tangent.xyz - (_160 * dot(_160, i.world_tangent.xyz)));\n    vec3 _212 = normalize(((_184 * m.x) + ((cross(_160, _184) * i.world_tangent.w) * m.y)) + (_160 * m.z));\n    vec3 _215;\n    if (i.front_facing)\n    {\n        _215 = _212;\n    }\n    else\n    {\n        _215 = -_212;\n    }\n    return _215;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1468 = fa_tex_fix(param_2, param_3);\n    vec4 _2424 = base_t;\n    _2424.x = _1468.x;\n    _2424.y = _1468.y;\n    _2424.z = _1468.z;\n    base_t = _2424;\n    vec4 _1482 = (_2424 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2371 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1514 = fa_tex_fix(param_6, param_7);\n        vec3 _1518 = (_1514 * 2.0) - vec3(1.0);\n        vec2 _1523 = _1518.xy * fa_mesh_fs_params[6].x;\n        vec3 _2432 = _1518;\n        _2432.x = _1523.x;\n        _2432.y = _1523.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2432;\n        _2371 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1552 = fa_tex_fix(param_12, param_13);\n    vec4 _2435 = mrt;\n    _2435.x = _1552.x;\n    _2435.y = _1552.y;\n    _2435.z = _1552.z;\n    mrt = _2435;\n    vec4 _1581 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1581.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1593 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1623 = fa_tex_fix(param_20, param_21);\n    float _2376 = fa_mesh_fs_params[20].x;\n    float _2377 = fa_mesh_fs_params[20].y;\n    float _2380 = fa_mesh_fs_params[20].z;\n    float _2379 = fa_mesh_fs_params[21].w;\n    float _2382 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2376 *= _1593.y;\n            _2377 *= _1593.z;\n            _2379 *= _1581.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2380 *= mrt.x;\n            _2382 *= mrt.w;\n        }\n    }\n    return Surface(_1482.xyz, _1482.w, _2371, clamp(fa_mesh_fs_params[5].x * _1552.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1552.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1593.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1623), _2376, _2377, fa_mesh_fs_params[21].xyz, _2379, _2380, fa_mesh_fs_params[20].w, _2382, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _271 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _277 = fa_light_texel(param_1);\n    float _280 = _277.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _286 = _280 < 0.5;\n    vec3 l;\n    if (_286)\n    {\n        l = normalize(_271.xyz);\n    }\n    else\n    {\n        vec3 _298 = _271.xyz - world_pos;\n        float _300 = length(_298);\n        dist = _300;\n        l = _298 / vec3(max(_300, 9.9999997473787516355514526367188e-05));\n        float _315 = _300 / max(_271.w, 0.001000000047497451305389404296875);\n        float _321 = clamp(1.0 - (_315 * _315), 0.0, 1.0);\n        atten = _321 * _321;\n        if (_280 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _335 = fa_light_texel(param_2);\n            float _345 = _335.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _351 = fa_light_texel(param_3);\n            float _352 = _351.x;\n            float cos_inner = _352;\n            if (_352 > 1.5)\n            {\n                cos_inner = mix(_345, 1.0, 0.25);\n            }\n            atten *= smoothstep(_345, cos_inner, dot(-l, normalize(_335.xyz)));\n        }\n    }\n    int _382;\n    if (_286)\n    {\n        _382 = 0;\n    }\n    else\n    {\n        _382 = (_280 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _277.xyz * atten, atten, 1.0, dist, _382);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _622;\n    if (i == 0)\n    {\n        _622 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _638;\n        if (i == 1)\n        {\n            _638 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _646;\n            if (i == 2)\n            {\n                _646 = fa_shadows[24].z;\n            }\n            else\n            {\n                _646 = fa_shadows[24].w;\n            }\n            _638 = _646;\n        }\n        _622 = _638;\n    }\n    return _622;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _610 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_610), sin(_610)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _684 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _689 = clamp(dot(n, l), 0.0, 1.0);\n    float _695 = sqrt(1.0 - (_689 * _689));\n    float _703 = min(_695 / max(_689, 0.20000000298023223876953125), 4.0);\n    float _708;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _708 = fa_shadows[26].y;\n    }\n    else\n    {\n        _708 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _733 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_708 * _695)), 1.0);\n    float _740 = _733.x;\n    bool _743 = _740 < fa_shadows[ci * 1 + 16].x;\n    bool _752;\n    if (!_743)\n    {\n        _752 = _740 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _752 = _743;\n    }\n    bool _761;\n    if (!_752)\n    {\n        _761 = _733.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _761 = _752;\n    }\n    bool _770;\n    if (!_761)\n    {\n        _770 = _733.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _733.z > 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    if (_777)\n    {\n        return -1.0;\n    }\n    float _786;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _786 = fa_shadows[26].x;\n    }\n    else\n    {\n        _786 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _805 = _733.z - ((_786 * (1.0 + (0.5 * _703))) / _684);\n    float _814 = ((fa_shadows[ci * 1 + 20].x * min(_703, 3.0)) * 0.5) / _684;\n    int _823 = int(fa_shadows[25].z + 0.5);\n    if (_823 == 1)\n    {\n        vec2 param = _733.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _834 = fa_shadow_depth(param, param_1);\n        return float(_805 <= _834);\n    }\n    float _841 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _844 = _823 == 2;\n    if (_844)\n    {\n        float _858 = clamp(((fa_shadows[25].w * _684) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _841;\n            vec2 _877 = fa_shadow_vogel(param_2, param_3, param_4) * _858;\n            vec2 param_5 = _733.xy + (_877 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _888 = fa_shadow_depth(param_5, param_6);\n            if (_888 < (_805 - (length(_877) * _814)))\n            {\n                sum += _888;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_805 - (sum / cnt), 0.0) * _684) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _932 = _844 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _932; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _932;\n        float param_9 = _841;\n        vec2 _951 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _733.xy + (_951 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _962 = fa_shadow_depth(param_10, param_11);\n        lit += float((_805 - (length(_951) * _814)) <= _962);\n    }\n    return lit / float(_932);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _992 = int(fa_shadows[25].x + 0.5);\n    if (_992 < 1)\n    {\n        return 1.0;\n    }\n    float _1008 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _992 - 1;\n    if (_1008 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1020 = _992 > 1;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _1008 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 1;\n    }\n    bool _1031 = _992 > 2;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _1008 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 2;\n    }\n    bool _1042 = _992 > 3;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1008 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _992)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1075 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1075;\n        if (_1075 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1100;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1100 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1100 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1119 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1100, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1130 = clamp((_1008 - (fa_shadow_split_at(param_7) - _1119)) / _1119, 0.0, 1.0);\n        if (_1130 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _992)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1151 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1151;\n                if (_1151 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1130);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1320 = fa_lm.z > 0.5;\n    bool _1326;\n    if (_1320)\n    {\n        int param = li;\n        _1326 = fa_light_baked(param);\n    }\n    else\n    {\n        _1326 = _1320;\n    }\n    if (_1326)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1350 = fa_light_sample(param_2, param_3);\n    vec3 _2356 = _1350.direction;\n    vec3 _2351 = _1350.color;\n    float _2353 = _1350.shadow;\n    int _2361 = _1350.type;\n    if ((_2361 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2356;\n        float _1364 = fa_shadow_factor(param_4, param_5);\n        _2353 = _1364;\n        _2351 *= _1364;\n    }\n    return LightSample(_2356, _2351, _1350.attenuation, _2353, _1350._distance, _2361);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1175 = int(fa_shadows[25].x + 0.5);\n    float _1185 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1190 = _1175 > 0;\n    bool _1199;\n    if (_1190)\n    {\n        int param = _1175 - 1;\n        _1199 = _1185 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1199 = _1190;\n    }\n    if (_1199)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1206 = _1175 > 1;\n        bool _1213;\n        if (_1206)\n        {\n            _1213 = _1185 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1213 = _1206;\n        }\n        if (_1213)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1219 = _1175 > 2;\n        bool _1226;\n        if (_1219)\n        {\n            _1226 = _1185 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1226 = _1219;\n        }\n        if (_1226)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1232 = _1175 > 3;\n        bool _1239;\n        if (_1232)\n        {\n            _1239 = _1185 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1239 = _1232;\n        }\n        if (_1239)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2167 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2167 = -_2167;\n    }\n    vec3 _1768 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n    Surface _1776 = fa_standard_surface(param_1);\n    vec3 _2206 = _1776.albedo;\n    float _2207 = _1776.alpha;\n    vec3 _2208 = _1776.normal;\n    float _2209 = _1776.metallic;\n    float _2210 = _1776.roughness;\n    float _2211 = _1776.occlusion;\n    vec3 _2212 = _1776.emission;\n    float _2213 = _1776.clearcoat;\n    float _2214 = _1776.clearcoat_roughness;\n    vec3 _2215 = _1776.sheen_color;\n    float _2216 = _1776.sheen_roughness;\n    float _2217 = _1776.anisotropy;\n    float _2218 = _1776.anisotropy_rotation;\n    float _2219 = _1776.specular;\n    float _2220 = _1776.ior;\n    vec3 _2221 = _1776.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n    Surface param_3 = _1776;\n    surface(param_2, param_3);\n    _2206 = param_3.albedo;\n    _2207 = param_3.alpha;\n    _2208 = param_3.normal;\n    _2209 = param_3.metallic;\n    _2210 = param_3.roughness;\n    _2211 = param_3.occlusion;\n    _2212 = param_3.emission;\n    _2213 = param_3.clearcoat;\n    _2214 = param_3.clearcoat_roughness;\n    _2215 = param_3.sheen_color;\n    _2216 = param_3.sheen_roughness;\n    _2217 = param_3.anisotropy;\n    _2218 = param_3.anisotropy_rotation;\n    _2219 = param_3.specular;\n    _2220 = param_3.ior;\n    _2221 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2206;\n    }\n    else\n    {\n        vec3 _1797 = _2208;\n        vec3 _1798 = normalize(_1797);\n        _2208 = _1798;\n        vec3 param_4 = _1798;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n        Surface param_6 = Surface(_2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _1817 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1817; ln++)\n        {\n            int param_8 = ln;\n            int _1830 = fa_cl_light(param_8);\n            bool _1833 = fa_lm.z > 0.5;\n            bool _1839;\n            if (_1833)\n            {\n                int param_9 = _1830;\n                _1839 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _1839 = _1833;\n            }\n            if (_1839)\n            {\n                continue;\n            }\n            int param_10 = _1830;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2167;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n            Surface param_14 = Surface(_2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _1866 = result;\n    vec3 _1867 = _1866 + _2212;\n    result = _1867;\n    vec3 param_16 = _1867;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _1876 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1883;\n    if (!_1876)\n    {\n        _1883 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1883 = _1876;\n    }\n    if (_1883)\n    {\n        vec3 _1892 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1898 = dot(_1892, fa_mesh_fs_params[9].xyz);\n        bool _1902 = fa_mesh_fs_params[9].w > 0.5;\n        float _1903;\n        if (_1902)\n        {\n            _1903 = _1898;\n        }\n        else\n        {\n            _1903 = length(_1892);\n        }\n        float _1915 = _1903 - fa_mesh_fs_params[8].x;\n        if (_1915 > 0.0)\n        {\n            float _1924 = fa_mesh_fs_params[7].w * _1915;\n            float tau = _1924 * _1924;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1940;\n                if (_1902)\n                {\n                    _1940 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1898);\n                }\n                else\n                {\n                    _1940 = fa_mesh_fs_params[0].y;\n                }\n                float _1961 = mix(_1940, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1903, 0.0, 1.0));\n                float _1965 = fa_world_pos.y - _1961;\n                float _1970 = _1961 - fa_mesh_fs_params[8].z;\n                float _1975 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1978 = _1970 <= 0.0;\n                bool _1979 = !_1978;\n                bool _1985;\n                if (_1979)\n                {\n                    _1985 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1985 = _1978;\n                }\n                float _1986;\n                if (_1985)\n                {\n                    _1986 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1986 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1970, 80.0));\n                }\n                bool _2013;\n                if (_1979)\n                {\n                    _2013 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2013 = _1978;\n                }\n                float _2014;\n                if (_2013)\n                {\n                    _2014 = fa_mesh_fs_params[8].y * _1970;\n                }\n                else\n                {\n                    _2014 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1970, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2039 = _1975 <= 0.0;\n                bool _2046;\n                if (!_2039)\n                {\n                    _2046 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2046 = _2039;\n                }\n                float _2047;\n                if (_2046)\n                {\n                    _2047 = fa_mesh_fs_params[8].y * _1975;\n                }\n                else\n                {\n                    _2047 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1975, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2074;\n                if (abs(_1965) < 0.001000000047497451305389404296875)\n                {\n                    _2074 = _1986;\n                }\n                else\n                {\n                    _2074 = (_2047 - _2014) / _1965;\n                }\n                tau += (_1915 * max(_2074, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2207);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "inst_name": "_396",
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
            "inst_name": "_632",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _401 = fa_mesh_fs_params[19].x < 0.0;\n    bool _408;\n    if (!_401)\n    {\n        _408 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _408 = _401;\n    }\n    bool _416;\n    if (!_408)\n    {\n        _416 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _416 = _408;\n    }\n    bool _423;\n    if (!_416)\n    {\n        _423 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _423 = _416;\n    }\n    bool _430;\n    if (!_423)\n    {\n        _430 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    if (_430)\n    {\n        return ivec2(0);\n    }\n    vec4 _440 = vec4(world_pos, 1.0);\n    float _447 = dot(fa_mesh_fs_params[16], _440);\n    if (!(_447 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _469 = vec2(dot(fa_mesh_fs_params[14], _440), dot(fa_mesh_fs_params[15], _440)) / vec2(_447);\n    int _473 = int(fa_mesh_fs_params[18].x);\n    int _477 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _477) + clamp(int(floor(((_469.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _477 - 1)) * _473)) + clamp(int(floor(((_469.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _473 - 1);\n    vec4 _548 = fa_light_texel(param);\n    return ivec2(int(_548.x), int(_548.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1293 = fa_cluster_lookup(param);\n    fa_cl_slot = _1293.x;\n    fa_cl_local = _1293.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1429 = fa_linear_to_srgb(param);\n        c = _1429;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1437 = fa_srgb_to_linear(param_1);\n            c = _1437;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _160;\n    if (i.front_facing)\n    {\n        _160 = i.world_normal;\n    }\n    else\n    {\n        _160 = -i.world_normal;\n    }\n    vec3 _184 = normalize(i.world_tangent.xyz - (_160 * dot(_160, i.world_tangent.xyz)));\n    vec3 _212 = normalize(((_184 * m.x) + ((cross(_160, _184) * i.world_tangent.w) * m.y)) + (_160 * m.z));\n    vec3 _215;\n    if (i.front_facing)\n    {\n        _215 = _212;\n    }\n    else\n    {\n        _215 = -_212;\n    }\n    return _215;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1468 = fa_tex_fix(param_2, param_3);\n    vec4 _2424 = base_t;\n    _2424.x = _1468.x;\n    _2424.y = _1468.y;\n    _2424.z = _1468.z;\n    base_t = _2424;\n    vec4 _1482 = (_2424 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2371 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1514 = fa_tex_fix(param_6, param_7);\n        vec3 _1518 = (_1514 * 2.0) - vec3(1.0);\n        vec2 _1523 = _1518.xy * fa_mesh_fs_params[6].x;\n        vec3 _2432 = _1518;\n        _2432.x = _1523.x;\n        _2432.y = _1523.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2432;\n        _2371 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1552 = fa_tex_fix(param_12, param_13);\n    vec4 _2435 = mrt;\n    _2435.x = _1552.x;\n    _2435.y = _1552.y;\n    _2435.z = _1552.z;\n    mrt = _2435;\n    vec4 _1581 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1581.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1593 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1623 = fa_tex_fix(param_20, param_21);\n    float _2376 = fa_mesh_fs_params[20].x;\n    float _2377 = fa_mesh_fs_params[20].y;\n    float _2380 = fa_mesh_fs_params[20].z;\n    float _2379 = fa_mesh_fs_params[21].w;\n    float _2382 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2376 *= _1593.y;\n            _2377 *= _1593.z;\n            _2379 *= _1581.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2380 *= mrt.x;\n            _2382 *= mrt.w;\n        }\n    }\n    return Surface(_1482.xyz, _1482.w, _2371, clamp(fa_mesh_fs_params[5].x * _1552.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1552.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1593.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1623), _2376, _2377, fa_mesh_fs_params[21].xyz, _2379, _2380, fa_mesh_fs_params[20].w, _2382, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _271 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _277 = fa_light_texel(param_1);\n    float _280 = _277.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _286 = _280 < 0.5;\n    vec3 l;\n    if (_286)\n    {\n        l = normalize(_271.xyz);\n    }\n    else\n    {\n        vec3 _298 = _271.xyz - world_pos;\n        float _300 = length(_298);\n        dist = _300;\n        l = _298 / vec3(max(_300, 9.9999997473787516355514526367188e-05));\n        float _315 = _300 / max(_271.w, 0.001000000047497451305389404296875);\n        float _321 = clamp(1.0 - (_315 * _315), 0.0, 1.0);\n        atten = _321 * _321;\n        if (_280 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _335 = fa_light_texel(param_2);\n            float _345 = _335.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _351 = fa_light_texel(param_3);\n            float _352 = _351.x;\n            float cos_inner = _352;\n            if (_352 > 1.5)\n            {\n                cos_inner = mix(_345, 1.0, 0.25);\n            }\n            atten *= smoothstep(_345, cos_inner, dot(-l, normalize(_335.xyz)));\n        }\n    }\n    int _382;\n    if (_286)\n    {\n        _382 = 0;\n    }\n    else\n    {\n        _382 = (_280 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _277.xyz * atten, atten, 1.0, dist, _382);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _622;\n    if (i == 0)\n    {\n        _622 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _638;\n        if (i == 1)\n        {\n            _638 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _646;\n            if (i == 2)\n            {\n                _646 = fa_shadows[24].z;\n            }\n            else\n            {\n                _646 = fa_shadows[24].w;\n            }\n            _638 = _646;\n        }\n        _622 = _638;\n    }\n    return _622;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _610 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_610), sin(_610)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _684 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _689 = clamp(dot(n, l), 0.0, 1.0);\n    float _695 = sqrt(1.0 - (_689 * _689));\n    float _703 = min(_695 / max(_689, 0.20000000298023223876953125), 4.0);\n    float _708;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _708 = fa_shadows[26].y;\n    }\n    else\n    {\n        _708 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _733 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_708 * _695)), 1.0);\n    float _740 = _733.x;\n    bool _743 = _740 < fa_shadows[ci * 1 + 16].x;\n    bool _752;\n    if (!_743)\n    {\n        _752 = _740 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _752 = _743;\n    }\n    bool _761;\n    if (!_752)\n    {\n        _761 = _733.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _761 = _752;\n    }\n    bool _770;\n    if (!_761)\n    {\n        _770 = _733.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _770 = _761;\n    }\n    bool _777;\n    if (!_770)\n    {\n        _777 = _733.z > 1.0;\n    }\n    else\n    {\n        _777 = _770;\n    }\n    if (_777)\n    {\n        return -1.0;\n    }\n    float _786;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _786 = fa_shadows[26].x;\n    }\n    else\n    {\n        _786 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _805 = _733.z - ((_786 * (1.0 + (0.5 * _703))) / _684);\n    float _814 = ((fa_shadows[ci * 1 + 20].x * min(_703, 3.0)) * 0.5) / _684;\n    int _823 = int(fa_shadows[25].z + 0.5);\n    if (_823 == 1)\n    {\n        vec2 param = _733.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _834 = fa_shadow_depth(param, param_1);\n        return float(_805 <= _834);\n    }\n    float _841 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _844 = _823 == 2;\n    if (_844)\n    {\n        float _858 = clamp(((fa_shadows[25].w * _684) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _841;\n            vec2 _877 = fa_shadow_vogel(param_2, param_3, param_4) * _858;\n            vec2 param_5 = _733.xy + (_877 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _888 = fa_shadow_depth(param_5, param_6);\n            if (_888 < (_805 - (length(_877) * _814)))\n            {\n                sum += _888;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_805 - (sum / cnt), 0.0) * _684) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _932 = _844 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _932; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _932;\n        float param_9 = _841;\n        vec2 _951 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _733.xy + (_951 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _962 = fa_shadow_depth(param_10, param_11);\n        lit += float((_805 - (length(_951) * _814)) <= _962);\n    }\n    return lit / float(_932);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _992 = int(fa_shadows[25].x + 0.5);\n    if (_992 < 1)\n    {\n        return 1.0;\n    }\n    float _1008 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _992 - 1;\n    if (_1008 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1020 = _992 > 1;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _1008 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 1;\n    }\n    bool _1031 = _992 > 2;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _1008 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 2;\n    }\n    bool _1042 = _992 > 3;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1008 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _992)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1075 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1075;\n        if (_1075 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1100;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1100 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1100 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1119 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1100, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1130 = clamp((_1008 - (fa_shadow_split_at(param_7) - _1119)) / _1119, 0.0, 1.0);\n        if (_1130 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _992)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1151 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1151;\n                if (_1151 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1130);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1320 = fa_lm.z > 0.5;\n    bool _1326;\n    if (_1320)\n    {\n        int param = li;\n        _1326 = fa_light_baked(param);\n    }\n    else\n    {\n        _1326 = _1320;\n    }\n    if (_1326)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1350 = fa_light_sample(param_2, param_3);\n    vec3 _2356 = _1350.direction;\n    vec3 _2351 = _1350.color;\n    float _2353 = _1350.shadow;\n    int _2361 = _1350.type;\n    if ((_2361 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2356;\n        float _1364 = fa_shadow_factor(param_4, param_5);\n        _2353 = _1364;\n        _2351 *= _1364;\n    }\n    return LightSample(_2356, _2351, _1350.attenuation, _2353, _1350._distance, _2361);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1175 = int(fa_shadows[25].x + 0.5);\n    float _1185 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1190 = _1175 > 0;\n    bool _1199;\n    if (_1190)\n    {\n        int param = _1175 - 1;\n        _1199 = _1185 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1199 = _1190;\n    }\n    if (_1199)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1206 = _1175 > 1;\n        bool _1213;\n        if (_1206)\n        {\n            _1213 = _1185 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1213 = _1206;\n        }\n        if (_1213)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1219 = _1175 > 2;\n        bool _1226;\n        if (_1219)\n        {\n            _1226 = _1185 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1226 = _1219;\n        }\n        if (_1226)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1232 = _1175 > 3;\n        bool _1239;\n        if (_1232)\n        {\n            _1239 = _1185 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1239 = _1232;\n        }\n        if (_1239)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2167 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2167 = -_2167;\n    }\n    vec3 _1768 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n    Surface _1776 = fa_standard_surface(param_1);\n    vec3 _2206 = _1776.albedo;\n    float _2207 = _1776.alpha;\n    vec3 _2208 = _1776.normal;\n    float _2209 = _1776.metallic;\n    float _2210 = _1776.roughness;\n    float _2211 = _1776.occlusion;\n    vec3 _2212 = _1776.emission;\n    float _2213 = _1776.clearcoat;\n    float _2214 = _1776.clearcoat_roughness;\n    vec3 _2215 = _1776.sheen_color;\n    float _2216 = _1776.sheen_roughness;\n    float _2217 = _1776.anisotropy;\n    float _2218 = _1776.anisotropy_rotation;\n    float _2219 = _1776.specular;\n    float _2220 = _1776.ior;\n    vec3 _2221 = _1776.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n    Surface param_3 = _1776;\n    surface(param_2, param_3);\n    _2206 = param_3.albedo;\n    _2207 = param_3.alpha;\n    _2208 = param_3.normal;\n    _2209 = param_3.metallic;\n    _2210 = param_3.roughness;\n    _2211 = param_3.occlusion;\n    _2212 = param_3.emission;\n    _2213 = param_3.clearcoat;\n    _2214 = param_3.clearcoat_roughness;\n    _2215 = param_3.sheen_color;\n    _2216 = param_3.sheen_roughness;\n    _2217 = param_3.anisotropy;\n    _2218 = param_3.anisotropy_rotation;\n    _2219 = param_3.specular;\n    _2220 = param_3.ior;\n    _2221 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2206;\n    }\n    else\n    {\n        vec3 _1797 = _2208;\n        vec3 _1798 = normalize(_1797);\n        _2208 = _1798;\n        vec3 param_4 = _1798;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n        Surface param_6 = Surface(_2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _1817 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1817; ln++)\n        {\n            int param_8 = ln;\n            int _1830 = fa_cl_light(param_8);\n            bool _1833 = fa_lm.z > 0.5;\n            bool _1839;\n            if (_1833)\n            {\n                int param_9 = _1830;\n                _1839 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _1839 = _1833;\n            }\n            if (_1839)\n            {\n                continue;\n            }\n            int param_10 = _1830;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2167;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2167, fa_world_tangent, fa_uv, fa_vertex_color, _1768, gl_FrontFacing);\n            Surface param_14 = Surface(_2206, _2207, _2208, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220, _2221);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _1866 = result;\n    vec3 _1867 = _1866 + _2212;\n    result = _1867;\n    vec3 param_16 = _1867;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _1876 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1883;\n    if (!_1876)\n    {\n        _1883 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1883 = _1876;\n    }\n    if (_1883)\n    {\n        vec3 _1892 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1898 = dot(_1892, fa_mesh_fs_params[9].xyz);\n        bool _1902 = fa_mesh_fs_params[9].w > 0.5;\n        float _1903;\n        if (_1902)\n        {\n            _1903 = _1898;\n        }\n        else\n        {\n            _1903 = length(_1892);\n        }\n        float _1915 = _1903 - fa_mesh_fs_params[8].x;\n        if (_1915 > 0.0)\n        {\n            float _1924 = fa_mesh_fs_params[7].w * _1915;\n            float tau = _1924 * _1924;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1940;\n                if (_1902)\n                {\n                    _1940 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1898);\n                }\n                else\n                {\n                    _1940 = fa_mesh_fs_params[0].y;\n                }\n                float _1961 = mix(_1940, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1903, 0.0, 1.0));\n                float _1965 = fa_world_pos.y - _1961;\n                float _1970 = _1961 - fa_mesh_fs_params[8].z;\n                float _1975 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1978 = _1970 <= 0.0;\n                bool _1979 = !_1978;\n                bool _1985;\n                if (_1979)\n                {\n                    _1985 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1985 = _1978;\n                }\n                float _1986;\n                if (_1985)\n                {\n                    _1986 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1986 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1970, 80.0));\n                }\n                bool _2013;\n                if (_1979)\n                {\n                    _2013 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2013 = _1978;\n                }\n                float _2014;\n                if (_2013)\n                {\n                    _2014 = fa_mesh_fs_params[8].y * _1970;\n                }\n                else\n                {\n                    _2014 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1970, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2039 = _1975 <= 0.0;\n                bool _2046;\n                if (!_2039)\n                {\n                    _2046 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2046 = _2039;\n                }\n                float _2047;\n                if (_2046)\n                {\n                    _2047 = fa_mesh_fs_params[8].y * _1975;\n                }\n                else\n                {\n                    _2047 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1975, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2074;\n                if (abs(_1965) < 0.001000000047497451305389404296875)\n                {\n                    _2074 = _1986;\n                }\n                else\n                {\n                    _2074 = (_2047 - _2014) / _1965;\n                }\n                tau += (_1915 * max(_2074, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2207);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "inst_name": "_396",
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
            "inst_name": "_632",
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
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
