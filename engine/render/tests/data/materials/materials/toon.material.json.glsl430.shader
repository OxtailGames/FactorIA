{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _393 = fa_mesh_fs_params[19].x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return vec4(0.0);\n    }\n    vec4 _432 = vec4(world_pos, 1.0);\n    float _439 = dot(fa_mesh_fs_params[16], _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _461 = vec2(dot(fa_mesh_fs_params[14], _432), dot(fa_mesh_fs_params[15], _432)) / vec2(_439);\n    int _465 = int(fa_mesh_fs_params[18].x);\n    int _469 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _465 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _545 = fa_cluster_texel(param);\n    return ivec2(int(_545.x), int(_545.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1786 = fa_cluster_lookup(param);\n    fa_cl_slot = _1786.x;\n    fa_cl_local = _1786.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1903 = fa_linear_to_srgb(param);\n        c = _1903;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1911 = fa_srgb_to_linear(param_1);\n            c = _1911;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    vec3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    vec3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    vec3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1942 = fa_tex_fix(param_2, param_3);\n    vec4 _2681 = base_t;\n    _2681.x = _1942.x;\n    _2681.y = _1942.y;\n    _2681.z = _1942.z;\n    base_t = _2681;\n    vec4 _1956 = (_2681 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2611 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1988 = fa_tex_fix(param_6, param_7);\n        vec3 _1991 = (_1988 * 2.0) - vec3(1.0);\n        vec2 _1996 = _1991.xy * fa_mesh_fs_params[6].x;\n        vec3 _2689 = _1991;\n        _2689.x = _1996.x;\n        _2689.y = _1996.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2689;\n        _2611 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2025 = fa_tex_fix(param_12, param_13);\n    vec4 _2692 = mrt;\n    _2692.x = _2025.x;\n    _2692.y = _2025.y;\n    _2692.z = _2025.z;\n    mrt = _2692;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2064 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2091 = fa_tex_fix(param_20, param_21);\n    return Surface(_1956.xyz, _1956.w, _2611, clamp(fa_mesh_fs_params[5].x * _2025.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2025.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2064.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2091));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _626 = rect.zw - rect.xy;\n    vec2 _630 = _626 * atlas;\n    vec2 _634 = ddx * _630;\n    vec2 _638 = ddy * _630;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _626), clamp(0.5 * log2(max(max(dot(_634, _634), dot(_638, _638)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _673 = dFdx(world_pos);\n    vec3 _676 = dFdy(world_pos);\n    bool _679 = fa_mesh_fs_params[10].y < 0.5;\n    bool _686;\n    if (!_679)\n    {\n        _686 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _686 = _679;\n    }\n    if (_686)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _693 = fa_cluster_texel(param);\n    int _697 = int(_693.w);\n    if (_697 < 1)\n    {\n        return;\n    }\n    int _707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _707;\n    vec4 _711 = fa_light_texel(param_1);\n    vec2 _714 = _711.yz;\n    int _718 = int(_711.w);\n    int param_2 = _707 + 1;\n    vec4 _723 = fa_light_texel(param_2);\n    float _724 = _723.x;\n    int _730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _734 = int(_693.z);\n    vec3 _1000;\n    for (int k = 0; k < _697; k++)\n    {\n        int _747 = _734 + k;\n        int param_3 = _718 + (_747 >> 2);\n        int _765 = (_707 + 2) + (int(fa_light_texel(param_3)[_747 & 3]) * 7);\n        int param_4 = _765 + 6;\n        vec4 _770 = fa_light_texel(param_4);\n        if (((int(_770.w + 0.5) >> _730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _765;\n        vec4 _785 = fa_light_texel(param_5);\n        int param_6 = _765 + 1;\n        vec4 _790 = fa_light_texel(param_6);\n        int param_7 = _765 + 2;\n        vec4 _795 = fa_light_texel(param_7);\n        vec3 _798 = _785.xyz;\n        float _803 = dot(_798, world_pos) + _785.w;\n        vec3 _805 = _790.xyz;\n        float _810 = dot(_805, world_pos) + _790.w;\n        vec3 _812 = _795.xyz;\n        float _817 = dot(_812, world_pos) + _795.w;\n        bool _822 = abs(_803) > 0.5;\n        bool _830;\n        if (!_822)\n        {\n            _830 = abs(_810) > 0.5;\n        }\n        else\n        {\n            _830 = _822;\n        }\n        bool _838;\n        if (!_830)\n        {\n            _838 = abs(_817) > 0.5;\n        }\n        else\n        {\n            _838 = _830;\n        }\n        if (_838)\n        {\n            continue;\n        }\n        float _853 = clamp(dot(geo_normal, normalize(_812)) * _770.z, 0.0, 1.0);\n        if (_853 <= 0.0)\n        {\n            continue;\n        }\n        float _873 = (clamp((0.5 - abs(_817)) * 10.0, 0.0, 1.0) * _853) * _770.x;\n        vec2 _881 = vec2(_803 + 0.5, 0.5 - _810);\n        vec2 _891 = vec2(dot(_798, _673), dot(_805, _673));\n        vec2 _901 = vec2(dot(_798, _676), dot(_805, _676));\n        int param_8 = _765 + 5;\n        vec4 _906 = fa_light_texel(param_8);\n        int param_9 = _765 + 3;\n        vec4 _911 = fa_light_texel(param_9);\n        int param_10 = _765 + 4;\n        vec4 _916 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _906.xyz;\n        bool _926 = _911.z > _911.x;\n        if (_926)\n        {\n            vec4 param_11 = _911;\n            vec2 param_12 = _881;\n            vec2 param_13 = _714;\n            vec2 param_14 = _891;\n            vec2 param_15 = _901;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_724 > 0.5) && (_724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _952 = fa_dc_to_linear(param_16);\n                vec4 _2649 = tx;\n                _2649.x = _952.x;\n                _2649.y = _952.y;\n                _2649.z = _952.z;\n                tx = _2649;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_873 * tex_a) * _906.w, 0.0, 1.0)));\n        if (_916.z > _916.x)\n        {\n            vec4 param_17 = _916;\n            vec2 param_18 = _881;\n            vec2 param_19 = _714;\n            vec2 param_20 = _891;\n            vec2 param_21 = _901;\n            vec4 _996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_724 > 1.5)\n            {\n                vec3 param_22 = _996.xyz;\n                vec3 _1006 = fa_dc_to_srgb(param_22);\n                _1000 = _1006;\n            }\n            else\n            {\n                _1000 = _996.xyz;\n            }\n            vec3 _1016 = (_1000 * 2.0) - vec3(1.0);\n            vec2 _1021 = _1016.xy * _770.y;\n            vec3 _1043 = (normalize(_798) * _1021.x) + (normalize(_805) * _1021.y);\n            vec3 _1046 = normalize(normal);\n            normal = normalize(mix(_1046, normalize((_1046 * max(_1016.z, 0.0500000007450580596923828125)) + (_1043 - (_1046 * dot(_1046, _1043)))), vec3(clamp(_873 * (_926 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    vec3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        vec3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / vec3(max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _267.xyz * atten, atten, 1.0, dist, _374);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1118;\n    if (i == 0)\n    {\n        _1118 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1134;\n        if (i == 1)\n        {\n            _1134 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1142;\n            if (i == 2)\n            {\n                _1142 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1142 = fa_shadows[24].w;\n            }\n            _1134 = _1142;\n        }\n        _1118 = _1134;\n    }\n    return _1118;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1106 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1106), sin(_1106)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1180 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1185 = clamp(dot(n, l), 0.0, 1.0);\n    float _1191 = sqrt(1.0 - (_1185 * _1185));\n    float _1198 = min(_1191 / max(_1185, 0.20000000298023223876953125), 4.0);\n    float _1203;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1203 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1203 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1228 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1203 * _1191)), 1.0);\n    float _1235 = _1228.x;\n    bool _1238 = _1235 < fa_shadows[ci * 1 + 16].x;\n    bool _1247;\n    if (!_1238)\n    {\n        _1247 = _1235 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1247 = _1238;\n    }\n    bool _1256;\n    if (!_1247)\n    {\n        _1256 = _1228.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1256 = _1247;\n    }\n    bool _1265;\n    if (!_1256)\n    {\n        _1265 = _1228.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1265 = _1256;\n    }\n    bool _1272;\n    if (!_1265)\n    {\n        _1272 = _1228.z > 1.0;\n    }\n    else\n    {\n        _1272 = _1265;\n    }\n    if (_1272)\n    {\n        return -1.0;\n    }\n    float _1281;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1281 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1281 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1300 = _1228.z - ((_1281 * (1.0 + (0.5 * _1198))) / _1180);\n    float _1309 = ((fa_shadows[ci * 1 + 20].x * min(_1198, 3.0)) * 0.5) / _1180;\n    int _1318 = int(fa_shadows[25].z + 0.5);\n    if (_1318 == 1)\n    {\n        vec2 param = _1228.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1329 = fa_shadow_depth(param, param_1);\n        return float(_1300 <= _1329);\n    }\n    float _1336 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1339 = _1318 == 2;\n    if (_1339)\n    {\n        float _1353 = clamp(((fa_shadows[25].w * _1180) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1336;\n            vec2 _1372 = fa_shadow_vogel(param_2, param_3, param_4) * _1353;\n            vec2 param_5 = _1228.xy + (_1372 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1383 = fa_shadow_depth(param_5, param_6);\n            if (_1383 < (_1300 - (length(_1372) * _1309)))\n            {\n                sum += _1383;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1300 - (sum / cnt), 0.0) * _1180) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1427 = _1339 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1427; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1427;\n        float param_9 = _1336;\n        vec2 _1446 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1228.xy + (_1446 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1457 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1300 - (length(_1446) * _1309)) <= _1457);\n    }\n    return lit / float(_1427);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1487 = int(fa_shadows[25].x + 0.5);\n    if (_1487 < 1)\n    {\n        return 1.0;\n    }\n    float _1502 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1487 - 1;\n    if (_1502 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1514 = _1487 > 1;\n    bool _1521;\n    if (_1514)\n    {\n        _1521 = _1502 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        ci = 1;\n    }\n    bool _1525 = _1487 > 2;\n    bool _1532;\n    if (_1525)\n    {\n        _1532 = _1502 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1532 = _1525;\n    }\n    if (_1532)\n    {\n        ci = 2;\n    }\n    bool _1536 = _1487 > 3;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1502 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1487)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1569 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1569;\n        if (_1569 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1594;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1594 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1594 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1613 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1594, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1624 = clamp((_1502 - (fa_shadow_split_at(param_7) - _1613)) / _1613, 0.0, 1.0);\n        if (_1624 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1487)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1645 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1645;\n                if (_1645 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1624);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1814 = fa_light_sample(param, param_1);\n    vec3 _2596 = _1814.direction;\n    vec3 _2591 = _1814.color;\n    float _2593 = _1814.shadow;\n    int _2601 = _1814.type;\n    if ((_2601 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2596;\n        float _1828 = fa_shadow_factor(param_2, param_3);\n        _2593 = _1828;\n        _2591 *= _1828;\n    }\n    return LightSample(_2596, _2591, _1814.attenuation, _2593, _1814._distance, _2601);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1669 = int(fa_shadows[25].x + 0.5);\n    float _1679 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1684 = _1669 > 0;\n    bool _1693;\n    if (_1684)\n    {\n        int param = _1669 - 1;\n        _1693 = _1679 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1693 = _1684;\n    }\n    if (_1693)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1700 = _1669 > 1;\n        bool _1707;\n        if (_1700)\n        {\n            _1707 = _1679 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1707 = _1700;\n        }\n        if (_1707)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1713 = _1669 > 2;\n        bool _1720;\n        if (_1713)\n        {\n            _1720 = _1679 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1720 = _1713;\n        }\n        if (_1720)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1726 = _1669 > 3;\n        bool _1733;\n        if (_1726)\n        {\n            _1733 = _1679 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1733 = _1726;\n        }\n        if (_1733)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2490 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2490 = -_2490;\n    }\n    vec3 _2134 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n    Surface _2142 = fa_standard_surface(param_1);\n    vec3 _2521 = _2142.albedo;\n    float _2522 = _2142.alpha;\n    vec3 _2523 = _2142.normal;\n    float _2524 = _2142.metallic;\n    float _2525 = _2142.roughness;\n    float _2526 = _2142.occlusion;\n    vec3 _2527 = _2142.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n    Surface param_3 = _2142;\n    surface(param_2, param_3);\n    _2521 = param_3.albedo;\n    _2522 = param_3.alpha;\n    _2523 = param_3.normal;\n    _2524 = param_3.metallic;\n    _2525 = param_3.roughness;\n    _2526 = param_3.occlusion;\n    _2527 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2490;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2521 = param_6;\n    _2523 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2521;\n    }\n    else\n    {\n        vec3 _2180 = _2523;\n        vec3 _2181 = normalize(_2180);\n        _2523 = _2181;\n        vec3 param_8 = _2181;\n        vec3 lit = (fa_ambient_light(param_8) * _2521) * _2526;\n        int _2200 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2200; ln++)\n        {\n            int param_9 = ln;\n            int param_10 = fa_cl_light(param_9);\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2490;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n            Surface param_14 = Surface(_2521, _2522, _2523, _2524, _2525, _2526, _2527);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2237 = result;\n    vec3 _2238 = _2237 + _2527;\n    result = _2238;\n    vec3 param_16 = _2238;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2247 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2255;\n    if (!_2247)\n    {\n        _2255 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2255 = _2247;\n    }\n    if (_2255)\n    {\n        vec3 _2264 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2271 = dot(_2264, fa_mesh_fs_params[9].xyz);\n        bool _2275 = fa_mesh_fs_params[9].w > 0.5;\n        float _2276;\n        if (_2275)\n        {\n            _2276 = _2271;\n        }\n        else\n        {\n            _2276 = length(_2264);\n        }\n        float _2288 = _2276 - fa_mesh_fs_params[8].x;\n        if (_2288 > 0.0)\n        {\n            float _2297 = fa_mesh_fs_params[7].w * _2288;\n            float tau = _2297 * _2297;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2313;\n                if (_2275)\n                {\n                    _2313 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2271);\n                }\n                else\n                {\n                    _2313 = fa_mesh_fs_params[0].y;\n                }\n                float _2334 = mix(_2313, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2276, 0.0, 1.0));\n                float _2338 = fa_world_pos.y - _2334;\n                float _2343 = _2334 - fa_mesh_fs_params[8].z;\n                float _2348 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2351 = _2343 <= 0.0;\n                bool _2352 = !_2351;\n                bool _2358;\n                if (_2352)\n                {\n                    _2358 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2358 = _2351;\n                }\n                float _2359;\n                if (_2358)\n                {\n                    _2359 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2359 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2343, 80.0));\n                }\n                bool _2386;\n                if (_2352)\n                {\n                    _2386 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2386 = _2351;\n                }\n                float _2387;\n                if (_2386)\n                {\n                    _2387 = fa_mesh_fs_params[8].y * _2343;\n                }\n                else\n                {\n                    _2387 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2343, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2412 = _2348 <= 0.0;\n                bool _2419;\n                if (!_2412)\n                {\n                    _2419 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2419 = _2412;\n                }\n                float _2420;\n                if (_2419)\n                {\n                    _2420 = fa_mesh_fs_params[8].y * _2348;\n                }\n                else\n                {\n                    _2420 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2348, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2447;\n                if (abs(_2338) < 0.001000000047497451305389404296875)\n                {\n                    _2447 = _2359;\n                }\n                else\n                {\n                    _2447 = (_2420 - _2387) / _2338;\n                }\n                tau += (_2288 * max(_2447, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2522);\n}\n\n",
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
            "inst_name": "_388",
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
            "inst_name": "_1128",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _393 = fa_mesh_fs_params[19].x < 0.0;\n    bool _400;\n    if (!_393)\n    {\n        _400 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    bool _408;\n    if (!_400)\n    {\n        _408 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _408 = _400;\n    }\n    bool _415;\n    if (!_408)\n    {\n        _415 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _415 = _408;\n    }\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    if (_422)\n    {\n        return vec4(0.0);\n    }\n    vec4 _432 = vec4(world_pos, 1.0);\n    float _439 = dot(fa_mesh_fs_params[16], _432);\n    if (!(_439 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _461 = vec2(dot(fa_mesh_fs_params[14], _432), dot(fa_mesh_fs_params[15], _432)) / vec2(_439);\n    int _465 = int(fa_mesh_fs_params[18].x);\n    int _469 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _469) + clamp(int(floor(((_461.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _469 - 1)) * _465)) + clamp(int(floor(((_461.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _465 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _545 = fa_cluster_texel(param);\n    return ivec2(int(_545.x), int(_545.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1786 = fa_cluster_lookup(param);\n    fa_cl_slot = _1786.x;\n    fa_cl_local = _1786.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1903 = fa_linear_to_srgb(param);\n        c = _1903;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1911 = fa_srgb_to_linear(param_1);\n            c = _1911;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _169;\n    if (i.front_facing)\n    {\n        _169 = i.world_normal;\n    }\n    else\n    {\n        _169 = -i.world_normal;\n    }\n    vec3 _193 = normalize(i.world_tangent.xyz - (_169 * dot(_169, i.world_tangent.xyz)));\n    vec3 _221 = normalize(((_193 * m.x) + ((cross(_169, _193) * i.world_tangent.w) * m.y)) + (_169 * m.z));\n    vec3 _224;\n    if (i.front_facing)\n    {\n        _224 = _221;\n    }\n    else\n    {\n        _224 = -_221;\n    }\n    return _224;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1942 = fa_tex_fix(param_2, param_3);\n    vec4 _2681 = base_t;\n    _2681.x = _1942.x;\n    _2681.y = _1942.y;\n    _2681.z = _1942.z;\n    base_t = _2681;\n    vec4 _1956 = (_2681 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2611 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1988 = fa_tex_fix(param_6, param_7);\n        vec3 _1991 = (_1988 * 2.0) - vec3(1.0);\n        vec2 _1996 = _1991.xy * fa_mesh_fs_params[6].x;\n        vec3 _2689 = _1991;\n        _2689.x = _1996.x;\n        _2689.y = _1996.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2689;\n        _2611 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2025 = fa_tex_fix(param_12, param_13);\n    vec4 _2692 = mrt;\n    _2692.x = _2025.x;\n    _2692.y = _2025.y;\n    _2692.z = _2025.z;\n    mrt = _2692;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2064 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2091 = fa_tex_fix(param_20, param_21);\n    return Surface(_1956.xyz, _1956.w, _2611, clamp(fa_mesh_fs_params[5].x * _2025.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2025.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2064.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2091));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _626 = rect.zw - rect.xy;\n    vec2 _630 = _626 * atlas;\n    vec2 _634 = ddx * _630;\n    vec2 _638 = ddy * _630;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _626), clamp(0.5 * log2(max(max(dot(_634, _634), dot(_638, _638)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _673 = dFdx(world_pos);\n    vec3 _676 = dFdy(world_pos);\n    bool _679 = fa_mesh_fs_params[10].y < 0.5;\n    bool _686;\n    if (!_679)\n    {\n        _686 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _686 = _679;\n    }\n    if (_686)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _693 = fa_cluster_texel(param);\n    int _697 = int(_693.w);\n    if (_697 < 1)\n    {\n        return;\n    }\n    int _707 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _707;\n    vec4 _711 = fa_light_texel(param_1);\n    vec2 _714 = _711.yz;\n    int _718 = int(_711.w);\n    int param_2 = _707 + 1;\n    vec4 _723 = fa_light_texel(param_2);\n    float _724 = _723.x;\n    int _730 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _734 = int(_693.z);\n    vec3 _1000;\n    for (int k = 0; k < _697; k++)\n    {\n        int _747 = _734 + k;\n        int param_3 = _718 + (_747 >> 2);\n        int _765 = (_707 + 2) + (int(fa_light_texel(param_3)[_747 & 3]) * 7);\n        int param_4 = _765 + 6;\n        vec4 _770 = fa_light_texel(param_4);\n        if (((int(_770.w + 0.5) >> _730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _765;\n        vec4 _785 = fa_light_texel(param_5);\n        int param_6 = _765 + 1;\n        vec4 _790 = fa_light_texel(param_6);\n        int param_7 = _765 + 2;\n        vec4 _795 = fa_light_texel(param_7);\n        vec3 _798 = _785.xyz;\n        float _803 = dot(_798, world_pos) + _785.w;\n        vec3 _805 = _790.xyz;\n        float _810 = dot(_805, world_pos) + _790.w;\n        vec3 _812 = _795.xyz;\n        float _817 = dot(_812, world_pos) + _795.w;\n        bool _822 = abs(_803) > 0.5;\n        bool _830;\n        if (!_822)\n        {\n            _830 = abs(_810) > 0.5;\n        }\n        else\n        {\n            _830 = _822;\n        }\n        bool _838;\n        if (!_830)\n        {\n            _838 = abs(_817) > 0.5;\n        }\n        else\n        {\n            _838 = _830;\n        }\n        if (_838)\n        {\n            continue;\n        }\n        float _853 = clamp(dot(geo_normal, normalize(_812)) * _770.z, 0.0, 1.0);\n        if (_853 <= 0.0)\n        {\n            continue;\n        }\n        float _873 = (clamp((0.5 - abs(_817)) * 10.0, 0.0, 1.0) * _853) * _770.x;\n        vec2 _881 = vec2(_803 + 0.5, 0.5 - _810);\n        vec2 _891 = vec2(dot(_798, _673), dot(_805, _673));\n        vec2 _901 = vec2(dot(_798, _676), dot(_805, _676));\n        int param_8 = _765 + 5;\n        vec4 _906 = fa_light_texel(param_8);\n        int param_9 = _765 + 3;\n        vec4 _911 = fa_light_texel(param_9);\n        int param_10 = _765 + 4;\n        vec4 _916 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _906.xyz;\n        bool _926 = _911.z > _911.x;\n        if (_926)\n        {\n            vec4 param_11 = _911;\n            vec2 param_12 = _881;\n            vec2 param_13 = _714;\n            vec2 param_14 = _891;\n            vec2 param_15 = _901;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_724 > 0.5) && (_724 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _952 = fa_dc_to_linear(param_16);\n                vec4 _2649 = tx;\n                _2649.x = _952.x;\n                _2649.y = _952.y;\n                _2649.z = _952.z;\n                tx = _2649;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_873 * tex_a) * _906.w, 0.0, 1.0)));\n        if (_916.z > _916.x)\n        {\n            vec4 param_17 = _916;\n            vec2 param_18 = _881;\n            vec2 param_19 = _714;\n            vec2 param_20 = _891;\n            vec2 param_21 = _901;\n            vec4 _996 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_724 > 1.5)\n            {\n                vec3 param_22 = _996.xyz;\n                vec3 _1006 = fa_dc_to_srgb(param_22);\n                _1000 = _1006;\n            }\n            else\n            {\n                _1000 = _996.xyz;\n            }\n            vec3 _1016 = (_1000 * 2.0) - vec3(1.0);\n            vec2 _1021 = _1016.xy * _770.y;\n            vec3 _1043 = (normalize(_798) * _1021.x) + (normalize(_805) * _1021.y);\n            vec3 _1046 = normalize(normal);\n            normal = normalize(mix(_1046, normalize((_1046 * max(_1016.z, 0.0500000007450580596923828125)) + (_1043 - (_1046 * dot(_1046, _1043)))), vec3(clamp(_873 * (_926 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _261 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _267 = fa_light_texel(param_1);\n    float _270 = _267.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _277 = _270 < 0.5;\n    vec3 l;\n    if (_277)\n    {\n        l = normalize(_261.xyz);\n    }\n    else\n    {\n        vec3 _289 = _261.xyz - world_pos;\n        float _291 = length(_289);\n        dist = _291;\n        l = _289 / vec3(max(_291, 9.9999997473787516355514526367188e-05));\n        float _306 = _291 / max(_261.w, 0.001000000047497451305389404296875);\n        float _312 = clamp(1.0 - (_306 * _306), 0.0, 1.0);\n        atten = _312 * _312;\n        if (_270 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _326 = fa_light_texel(param_2);\n            float _336 = _326.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _343 = fa_light_texel(param_3);\n            float _344 = _343.x;\n            float cos_inner = _344;\n            if (_344 > 1.5)\n            {\n                cos_inner = mix(_336, 1.0, 0.25);\n            }\n            atten *= smoothstep(_336, cos_inner, dot(-l, normalize(_326.xyz)));\n        }\n    }\n    int _374;\n    if (_277)\n    {\n        _374 = 0;\n    }\n    else\n    {\n        _374 = (_270 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _267.xyz * atten, atten, 1.0, dist, _374);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1118;\n    if (i == 0)\n    {\n        _1118 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1134;\n        if (i == 1)\n        {\n            _1134 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1142;\n            if (i == 2)\n            {\n                _1142 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1142 = fa_shadows[24].w;\n            }\n            _1134 = _1142;\n        }\n        _1118 = _1134;\n    }\n    return _1118;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1106 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1106), sin(_1106)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1180 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1185 = clamp(dot(n, l), 0.0, 1.0);\n    float _1191 = sqrt(1.0 - (_1185 * _1185));\n    float _1198 = min(_1191 / max(_1185, 0.20000000298023223876953125), 4.0);\n    float _1203;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1203 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1203 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1228 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1203 * _1191)), 1.0);\n    float _1235 = _1228.x;\n    bool _1238 = _1235 < fa_shadows[ci * 1 + 16].x;\n    bool _1247;\n    if (!_1238)\n    {\n        _1247 = _1235 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1247 = _1238;\n    }\n    bool _1256;\n    if (!_1247)\n    {\n        _1256 = _1228.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1256 = _1247;\n    }\n    bool _1265;\n    if (!_1256)\n    {\n        _1265 = _1228.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1265 = _1256;\n    }\n    bool _1272;\n    if (!_1265)\n    {\n        _1272 = _1228.z > 1.0;\n    }\n    else\n    {\n        _1272 = _1265;\n    }\n    if (_1272)\n    {\n        return -1.0;\n    }\n    float _1281;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1281 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1281 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1300 = _1228.z - ((_1281 * (1.0 + (0.5 * _1198))) / _1180);\n    float _1309 = ((fa_shadows[ci * 1 + 20].x * min(_1198, 3.0)) * 0.5) / _1180;\n    int _1318 = int(fa_shadows[25].z + 0.5);\n    if (_1318 == 1)\n    {\n        vec2 param = _1228.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1329 = fa_shadow_depth(param, param_1);\n        return float(_1300 <= _1329);\n    }\n    float _1336 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1339 = _1318 == 2;\n    if (_1339)\n    {\n        float _1353 = clamp(((fa_shadows[25].w * _1180) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1336;\n            vec2 _1372 = fa_shadow_vogel(param_2, param_3, param_4) * _1353;\n            vec2 param_5 = _1228.xy + (_1372 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1383 = fa_shadow_depth(param_5, param_6);\n            if (_1383 < (_1300 - (length(_1372) * _1309)))\n            {\n                sum += _1383;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1300 - (sum / cnt), 0.0) * _1180) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1427 = _1339 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1427; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1427;\n        float param_9 = _1336;\n        vec2 _1446 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1228.xy + (_1446 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1457 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1300 - (length(_1446) * _1309)) <= _1457);\n    }\n    return lit / float(_1427);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1487 = int(fa_shadows[25].x + 0.5);\n    if (_1487 < 1)\n    {\n        return 1.0;\n    }\n    float _1502 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1487 - 1;\n    if (_1502 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1514 = _1487 > 1;\n    bool _1521;\n    if (_1514)\n    {\n        _1521 = _1502 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1521 = _1514;\n    }\n    if (_1521)\n    {\n        ci = 1;\n    }\n    bool _1525 = _1487 > 2;\n    bool _1532;\n    if (_1525)\n    {\n        _1532 = _1502 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1532 = _1525;\n    }\n    if (_1532)\n    {\n        ci = 2;\n    }\n    bool _1536 = _1487 > 3;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1502 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1487)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1569 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1569;\n        if (_1569 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1594;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1594 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1594 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1613 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1594, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1624 = clamp((_1502 - (fa_shadow_split_at(param_7) - _1613)) / _1613, 0.0, 1.0);\n        if (_1624 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1487)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1645 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1645;\n                if (_1645 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1624);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1814 = fa_light_sample(param, param_1);\n    vec3 _2596 = _1814.direction;\n    vec3 _2591 = _1814.color;\n    float _2593 = _1814.shadow;\n    int _2601 = _1814.type;\n    if ((_2601 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2596;\n        float _1828 = fa_shadow_factor(param_2, param_3);\n        _2593 = _1828;\n        _2591 *= _1828;\n    }\n    return LightSample(_2596, _2591, _1814.attenuation, _2593, _1814._distance, _2601);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1669 = int(fa_shadows[25].x + 0.5);\n    float _1679 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1684 = _1669 > 0;\n    bool _1693;\n    if (_1684)\n    {\n        int param = _1669 - 1;\n        _1693 = _1679 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1693 = _1684;\n    }\n    if (_1693)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1700 = _1669 > 1;\n        bool _1707;\n        if (_1700)\n        {\n            _1707 = _1679 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1707 = _1700;\n        }\n        if (_1707)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1713 = _1669 > 2;\n        bool _1720;\n        if (_1713)\n        {\n            _1720 = _1679 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1720 = _1713;\n        }\n        if (_1720)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1726 = _1669 > 3;\n        bool _1733;\n        if (_1726)\n        {\n            _1733 = _1679 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1733 = _1726;\n        }\n        if (_1733)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2490 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2490 = -_2490;\n    }\n    vec3 _2134 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n    Surface _2142 = fa_standard_surface(param_1);\n    vec3 _2521 = _2142.albedo;\n    float _2522 = _2142.alpha;\n    vec3 _2523 = _2142.normal;\n    float _2524 = _2142.metallic;\n    float _2525 = _2142.roughness;\n    float _2526 = _2142.occlusion;\n    vec3 _2527 = _2142.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n    Surface param_3 = _2142;\n    surface(param_2, param_3);\n    _2521 = param_3.albedo;\n    _2522 = param_3.alpha;\n    _2523 = param_3.normal;\n    _2524 = param_3.metallic;\n    _2525 = param_3.roughness;\n    _2526 = param_3.occlusion;\n    _2527 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2490;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2521 = param_6;\n    _2523 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2521;\n    }\n    else\n    {\n        vec3 _2180 = _2523;\n        vec3 _2181 = normalize(_2180);\n        _2523 = _2181;\n        vec3 param_8 = _2181;\n        vec3 lit = (fa_ambient_light(param_8) * _2521) * _2526;\n        int _2200 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2200; ln++)\n        {\n            int param_9 = ln;\n            int param_10 = fa_cl_light(param_9);\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2490;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2490, fa_world_tangent, fa_uv, fa_vertex_color, _2134, gl_FrontFacing);\n            Surface param_14 = Surface(_2521, _2522, _2523, _2524, _2525, _2526, _2527);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2237 = result;\n    vec3 _2238 = _2237 + _2527;\n    result = _2238;\n    vec3 param_16 = _2238;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2247 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2255;\n    if (!_2247)\n    {\n        _2255 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2255 = _2247;\n    }\n    if (_2255)\n    {\n        vec3 _2264 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2271 = dot(_2264, fa_mesh_fs_params[9].xyz);\n        bool _2275 = fa_mesh_fs_params[9].w > 0.5;\n        float _2276;\n        if (_2275)\n        {\n            _2276 = _2271;\n        }\n        else\n        {\n            _2276 = length(_2264);\n        }\n        float _2288 = _2276 - fa_mesh_fs_params[8].x;\n        if (_2288 > 0.0)\n        {\n            float _2297 = fa_mesh_fs_params[7].w * _2288;\n            float tau = _2297 * _2297;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2313;\n                if (_2275)\n                {\n                    _2313 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2271);\n                }\n                else\n                {\n                    _2313 = fa_mesh_fs_params[0].y;\n                }\n                float _2334 = mix(_2313, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2276, 0.0, 1.0));\n                float _2338 = fa_world_pos.y - _2334;\n                float _2343 = _2334 - fa_mesh_fs_params[8].z;\n                float _2348 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2351 = _2343 <= 0.0;\n                bool _2352 = !_2351;\n                bool _2358;\n                if (_2352)\n                {\n                    _2358 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2358 = _2351;\n                }\n                float _2359;\n                if (_2358)\n                {\n                    _2359 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2359 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2343, 80.0));\n                }\n                bool _2386;\n                if (_2352)\n                {\n                    _2386 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2386 = _2351;\n                }\n                float _2387;\n                if (_2386)\n                {\n                    _2387 = fa_mesh_fs_params[8].y * _2343;\n                }\n                else\n                {\n                    _2387 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2343, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2412 = _2348 <= 0.0;\n                bool _2419;\n                if (!_2412)\n                {\n                    _2419 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2419 = _2412;\n                }\n                float _2420;\n                if (_2419)\n                {\n                    _2420 = fa_mesh_fs_params[8].y * _2348;\n                }\n                else\n                {\n                    _2420 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2348, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2447;\n                if (abs(_2338) < 0.001000000047497451305389404296875)\n                {\n                    _2447 = _2359;\n                }\n                else\n                {\n                    _2447 = (_2420 - _2387) / _2338;\n                }\n                tau += (_2288 * max(_2447, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2522);\n}\n\n",
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
            "inst_name": "_388",
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
            "inst_name": "_1128",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    vec4 _241 = (_591 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _572 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _572, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _591 = base_t;\n    _591.x = _225.x;\n    _591.y = _225.y;\n    _591.z = _225.z;\n    base_t = _591;\n    vec4 _241 = (_591 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _572 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _599 = _279;\n        _599.x = _284.x;\n        _599.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _599;\n        _572 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _602 = mrt;\n    _602.x = _313.x;\n    _602.y = _313.y;\n    _602.z = _313.z;\n    mrt = _602;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _572, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _519 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _519 = -_519;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _519, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
