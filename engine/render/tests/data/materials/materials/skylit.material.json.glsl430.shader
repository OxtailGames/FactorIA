{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _420 = fa_mesh_fs_params[19].x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return vec4(0.0);\n    }\n    vec4 _459 = vec4(world_pos, 1.0);\n    float _466 = dot(fa_mesh_fs_params[16], _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _488 = vec2(dot(fa_mesh_fs_params[14], _459), dot(fa_mesh_fs_params[15], _459)) / vec2(_466);\n    int _492 = int(fa_mesh_fs_params[18].x);\n    int _496 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _492 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _572 = fa_cluster_texel(param);\n    return ivec2(int(_572.x), int(_572.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2003 = fa_cluster_lookup(param);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _196;\n    if (i.front_facing)\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    vec3 _220 = normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    vec3 _248 = normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    vec3 _251;\n    if (i.front_facing)\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2140 = fa_tex_fix(param_2, param_3);\n    vec4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    vec4 _2154 = (_2900 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2824 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2186 = fa_tex_fix(param_6, param_7);\n        vec3 _2189 = (_2186 * 2.0) - vec3(1.0);\n        vec2 _2194 = _2189.xy * fa_mesh_fs_params[6].x;\n        vec3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2223 = fa_tex_fix(param_12, param_13);\n    vec4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2289 = fa_tex_fix(param_20, param_21);\n    return Surface(_2154.xyz, _2154.w, _2824, clamp(fa_mesh_fs_params[5].x * _2223.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2223.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2262.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2289));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _653 = rect.zw - rect.xy;\n    vec2 _657 = _653 * atlas;\n    vec2 _661 = ddx * _657;\n    vec2 _665 = ddy * _657;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _653), clamp(0.5 * log2(max(max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _700 = dFdx(world_pos);\n    vec3 _703 = dFdy(world_pos);\n    bool _706 = fa_mesh_fs_params[10].y < 0.5;\n    bool _713;\n    if (!_706)\n    {\n        _713 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _720 = fa_cluster_texel(param);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _734;\n    vec4 _738 = fa_light_texel(param_1);\n    vec2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    vec4 _750 = fa_light_texel(param_2);\n    float _751 = _750.x;\n    int _757 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _761 = int(_720.z);\n    vec3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        vec4 _797 = fa_light_texel(param_4);\n        if (((int(_797.w + 0.5) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        vec4 _812 = fa_light_texel(param_5);\n        int param_6 = _792 + 1;\n        vec4 _817 = fa_light_texel(param_6);\n        int param_7 = _792 + 2;\n        vec4 _822 = fa_light_texel(param_7);\n        vec3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        vec3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        vec3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = clamp(dot(geo_normal, normalize(_839)) * _797.z, 0.0, 1.0);\n        if (_880 <= 0.0)\n        {\n            continue;\n        }\n        float _900 = (clamp((0.5 - abs(_844)) * 10.0, 0.0, 1.0) * _880) * _797.x;\n        vec2 _908 = vec2(_830 + 0.5, 0.5 - _837);\n        vec2 _918 = vec2(dot(_825, _700), dot(_832, _700));\n        vec2 _928 = vec2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        vec4 _933 = fa_light_texel(param_8);\n        int param_9 = _792 + 3;\n        vec4 _938 = fa_light_texel(param_9);\n        int param_10 = _792 + 4;\n        vec4 _943 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            vec4 param_11 = _938;\n            vec2 param_12 = _908;\n            vec2 param_13 = _741;\n            vec2 param_14 = _918;\n            vec2 param_15 = _928;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_751 > 0.5) && (_751 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _979 = fa_dc_to_linear(param_16);\n                vec4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_900 * tex_a) * _933.w, 0.0, 1.0)));\n        if (_943.z > _943.x)\n        {\n            vec4 param_17 = _943;\n            vec2 param_18 = _908;\n            vec2 param_19 = _741;\n            vec2 param_20 = _918;\n            vec2 param_21 = _928;\n            vec4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_751 > 1.5)\n            {\n                vec3 param_22 = _1023.xyz;\n                vec3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            vec3 _1043 = (_1027 * 2.0) - vec3(1.0);\n            vec2 _1048 = _1043.xy * _797.y;\n            vec3 _1070 = (normalize(_825) * _1048.x) + (normalize(_832) * _1048.y);\n            vec3 _1073 = normalize(normal);\n            normal = normalize(mix(_1073, normalize((_1073 * max(_1043.z, 0.0500000007450580596923828125)) + (_1070 - (_1073 * dot(_1073, _1070)))), vec3(clamp(_900 * (_953 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1902 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1905 = _1902.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1905 * _1905, exp2((-9.27999973297119140625) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625 * _1808;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1808)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1838, 0.0500000007450580596923828125 + _1838, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1808 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1944 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1944.x) + vec3(_1944.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    vec3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        vec3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / vec3(max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _294.xyz * atten, atten, 1.0, dist, _401);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1169 = fa_shadows[24].w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1207 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1212 = clamp(dot(n, l), 0.0, 1.0);\n    float _1218 = sqrt(1.0 - (_1212 * _1212));\n    float _1225 = min(_1218 / max(_1212, 0.20000000298023223876953125), 4.0);\n    float _1230;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1230 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1230 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1255 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1230 * _1218)), 1.0);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < fa_shadows[ci * 1 + 16].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0;\n    }\n    float _1308;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1308 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1308 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0 + (0.5 * _1225))) / _1207);\n    float _1336 = ((fa_shadows[ci * 1 + 20].x * min(_1225, 3.0)) * 0.5) / _1207;\n    int _1345 = int(fa_shadows[25].z + 0.5);\n    if (_1345 == 1)\n    {\n        vec2 param = _1255.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1356 = fa_shadow_depth(param, param_1);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = clamp(((fa_shadows[25].w * _1207) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            vec2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            vec2 param_5 = _1255.xy + (_1399 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1410 = fa_shadow_depth(param_5, param_6);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1327 - (sum / cnt), 0.0) * _1207) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        vec2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1255.xy + (_1473 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1484 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1514 = int(fa_shadows[25].x + 0.5);\n    if (_1514 < 1)\n    {\n        return 1.0;\n    }\n    float _1529 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1596;\n        if (_1596 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1621 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1640 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1621, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1651 = clamp((_1529 - (fa_shadow_split_at(param_7) - _1640)) / _1640, 0.0, 1.0);\n        if (_1651 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1672;\n                if (_1672 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1);\n    vec3 _2809 = _2031.direction;\n    vec3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    return LightSample(_2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1696 = int(fa_shadows[25].x + 0.5);\n    float _1706 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2687 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    vec3 _2332 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n    Surface _2340 = fa_standard_surface(param_1);\n    vec3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    vec3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    vec3 _2732 = _2340.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2687;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2726 = param_6;\n    _2728 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2726;\n    }\n    else\n    {\n        vec3 _2378 = _2728;\n        vec3 _2379 = normalize(_2378);\n        _2728 = _2379;\n        vec3 param_8 = _2379;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n        Surface param_10 = Surface(_2726, _2727, _2728, _2729, _2730, _2731, _2732);\n        vec3 param_11 = fa_ambient_light(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _2687;\n            SurfaceInput param_16 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n            Surface param_17 = Surface(_2726, _2727, _2728, _2729, _2730, _2731, _2732);\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    vec3 _2435 = result;\n    vec3 _2436 = _2435 + _2732;\n    result = _2436;\n    vec3 param_19 = _2436;\n    vec3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2445 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        vec3 _2462 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2469 = dot(_2462, fa_mesh_fs_params[9].xyz);\n        bool _2473 = fa_mesh_fs_params[9].w > 0.5;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - fa_mesh_fs_params[8].x;\n        if (_2486 > 0.0)\n        {\n            float _2495 = fa_mesh_fs_params[7].w * _2486;\n            float tau = _2495 * _2495;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2469);\n                }\n                else\n                {\n                    _2511 = fa_mesh_fs_params[0].y;\n                }\n                float _2532 = mix(_2511, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2474, 0.0, 1.0));\n                float _2536 = fa_world_pos.y - _2532;\n                float _2541 = _2532 - fa_mesh_fs_params[8].z;\n                float _2546 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2549 = _2541 <= 0.0;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2557 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2541, 80.0));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = fa_mesh_fs_params[8].y * _2541;\n                }\n                else\n                {\n                    _2585 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2541, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2610 = _2546 <= 0.0;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = fa_mesh_fs_params[8].y * _2546;\n                }\n                else\n                {\n                    _2618 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2546, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * max(_2645, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2727);\n}\n\n",
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
            "inst_name": "_415",
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
            "inst_name": "_1155",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _420 = fa_mesh_fs_params[19].x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return vec4(0.0);\n    }\n    vec4 _459 = vec4(world_pos, 1.0);\n    float _466 = dot(fa_mesh_fs_params[16], _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _488 = vec2(dot(fa_mesh_fs_params[14], _459), dot(fa_mesh_fs_params[15], _459)) / vec2(_466);\n    int _492 = int(fa_mesh_fs_params[18].x);\n    int _496 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _492 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _572 = fa_cluster_texel(param);\n    return ivec2(int(_572.x), int(_572.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2003 = fa_cluster_lookup(param);\n    fa_cl_slot = _2003.x;\n    fa_cl_local = _2003.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2101 = fa_linear_to_srgb(param);\n        c = _2101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2109 = fa_srgb_to_linear(param_1);\n            c = _2109;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _196;\n    if (i.front_facing)\n    {\n        _196 = i.world_normal;\n    }\n    else\n    {\n        _196 = -i.world_normal;\n    }\n    vec3 _220 = normalize(i.world_tangent.xyz - (_196 * dot(_196, i.world_tangent.xyz)));\n    vec3 _248 = normalize(((_220 * m.x) + ((cross(_196, _220) * i.world_tangent.w) * m.y)) + (_196 * m.z));\n    vec3 _251;\n    if (i.front_facing)\n    {\n        _251 = _248;\n    }\n    else\n    {\n        _251 = -_248;\n    }\n    return _251;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2140 = fa_tex_fix(param_2, param_3);\n    vec4 _2900 = base_t;\n    _2900.x = _2140.x;\n    _2900.y = _2140.y;\n    _2900.z = _2140.z;\n    base_t = _2900;\n    vec4 _2154 = (_2900 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2824 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2186 = fa_tex_fix(param_6, param_7);\n        vec3 _2189 = (_2186 * 2.0) - vec3(1.0);\n        vec2 _2194 = _2189.xy * fa_mesh_fs_params[6].x;\n        vec3 _2908 = _2189;\n        _2908.x = _2194.x;\n        _2908.y = _2194.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2908;\n        _2824 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2223 = fa_tex_fix(param_12, param_13);\n    vec4 _2911 = mrt;\n    _2911.x = _2223.x;\n    _2911.y = _2223.y;\n    _2911.z = _2223.z;\n    mrt = _2911;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2262 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2289 = fa_tex_fix(param_20, param_21);\n    return Surface(_2154.xyz, _2154.w, _2824, clamp(fa_mesh_fs_params[5].x * _2223.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2223.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2262.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2289));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _653 = rect.zw - rect.xy;\n    vec2 _657 = _653 * atlas;\n    vec2 _661 = ddx * _657;\n    vec2 _665 = ddy * _657;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _653), clamp(0.5 * log2(max(max(dot(_661, _661), dot(_665, _665)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _700 = dFdx(world_pos);\n    vec3 _703 = dFdy(world_pos);\n    bool _706 = fa_mesh_fs_params[10].y < 0.5;\n    bool _713;\n    if (!_706)\n    {\n        _713 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _713 = _706;\n    }\n    if (_713)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _720 = fa_cluster_texel(param);\n    int _724 = int(_720.w);\n    if (_724 < 1)\n    {\n        return;\n    }\n    int _734 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _734;\n    vec4 _738 = fa_light_texel(param_1);\n    vec2 _741 = _738.yz;\n    int _745 = int(_738.w);\n    int param_2 = _734 + 1;\n    vec4 _750 = fa_light_texel(param_2);\n    float _751 = _750.x;\n    int _757 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _761 = int(_720.z);\n    vec3 _1027;\n    for (int k = 0; k < _724; k++)\n    {\n        int _774 = _761 + k;\n        int param_3 = _745 + (_774 >> 2);\n        int _792 = (_734 + 2) + (int(fa_light_texel(param_3)[_774 & 3]) * 7);\n        int param_4 = _792 + 6;\n        vec4 _797 = fa_light_texel(param_4);\n        if (((int(_797.w + 0.5) >> _757) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _792;\n        vec4 _812 = fa_light_texel(param_5);\n        int param_6 = _792 + 1;\n        vec4 _817 = fa_light_texel(param_6);\n        int param_7 = _792 + 2;\n        vec4 _822 = fa_light_texel(param_7);\n        vec3 _825 = _812.xyz;\n        float _830 = dot(_825, world_pos) + _812.w;\n        vec3 _832 = _817.xyz;\n        float _837 = dot(_832, world_pos) + _817.w;\n        vec3 _839 = _822.xyz;\n        float _844 = dot(_839, world_pos) + _822.w;\n        bool _849 = abs(_830) > 0.5;\n        bool _857;\n        if (!_849)\n        {\n            _857 = abs(_837) > 0.5;\n        }\n        else\n        {\n            _857 = _849;\n        }\n        bool _865;\n        if (!_857)\n        {\n            _865 = abs(_844) > 0.5;\n        }\n        else\n        {\n            _865 = _857;\n        }\n        if (_865)\n        {\n            continue;\n        }\n        float _880 = clamp(dot(geo_normal, normalize(_839)) * _797.z, 0.0, 1.0);\n        if (_880 <= 0.0)\n        {\n            continue;\n        }\n        float _900 = (clamp((0.5 - abs(_844)) * 10.0, 0.0, 1.0) * _880) * _797.x;\n        vec2 _908 = vec2(_830 + 0.5, 0.5 - _837);\n        vec2 _918 = vec2(dot(_825, _700), dot(_832, _700));\n        vec2 _928 = vec2(dot(_825, _703), dot(_832, _703));\n        int param_8 = _792 + 5;\n        vec4 _933 = fa_light_texel(param_8);\n        int param_9 = _792 + 3;\n        vec4 _938 = fa_light_texel(param_9);\n        int param_10 = _792 + 4;\n        vec4 _943 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _933.xyz;\n        bool _953 = _938.z > _938.x;\n        if (_953)\n        {\n            vec4 param_11 = _938;\n            vec2 param_12 = _908;\n            vec2 param_13 = _741;\n            vec2 param_14 = _918;\n            vec2 param_15 = _928;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_751 > 0.5) && (_751 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _979 = fa_dc_to_linear(param_16);\n                vec4 _2862 = tx;\n                _2862.x = _979.x;\n                _2862.y = _979.y;\n                _2862.z = _979.z;\n                tx = _2862;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_900 * tex_a) * _933.w, 0.0, 1.0)));\n        if (_943.z > _943.x)\n        {\n            vec4 param_17 = _943;\n            vec2 param_18 = _908;\n            vec2 param_19 = _741;\n            vec2 param_20 = _918;\n            vec2 param_21 = _928;\n            vec4 _1023 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_751 > 1.5)\n            {\n                vec3 param_22 = _1023.xyz;\n                vec3 _1033 = fa_dc_to_srgb(param_22);\n                _1027 = _1033;\n            }\n            else\n            {\n                _1027 = _1023.xyz;\n            }\n            vec3 _1043 = (_1027 * 2.0) - vec3(1.0);\n            vec2 _1048 = _1043.xy * _797.y;\n            vec3 _1070 = (normalize(_825) * _1048.x) + (normalize(_832) * _1048.y);\n            vec3 _1073 = normalize(normal);\n            normal = normalize(mix(_1073, normalize((_1073 * max(_1043.z, 0.0500000007450580596923828125)) + (_1070 - (_1073 * dot(_1073, _1070)))), vec3(clamp(_900 * (_953 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1902 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1905 = _1902.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1905 * _1905, exp2((-9.27999973297119140625) * ndv)) * _1905) + _1902.y)) + _1902.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1808 = rough * rough;\n    float _1838 = 0.60000002384185791015625 * _1808;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1808)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1838, 0.0500000007450580596923828125 + _1838, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1808 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1944 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1944.x) + vec3(_1944.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    vec3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        vec3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / vec3(max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _401;\n    if (_304)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _294.xyz * atten, atten, 1.0, dist, _401);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1145;\n    if (i == 0)\n    {\n        _1145 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1161;\n        if (i == 1)\n        {\n            _1161 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1169;\n            if (i == 2)\n            {\n                _1169 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1169 = fa_shadows[24].w;\n            }\n            _1161 = _1169;\n        }\n        _1145 = _1161;\n    }\n    return _1145;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1133 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1133), sin(_1133)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1207 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1212 = clamp(dot(n, l), 0.0, 1.0);\n    float _1218 = sqrt(1.0 - (_1212 * _1212));\n    float _1225 = min(_1218 / max(_1212, 0.20000000298023223876953125), 4.0);\n    float _1230;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1230 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1230 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1255 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1230 * _1218)), 1.0);\n    float _1262 = _1255.x;\n    bool _1265 = _1262 < fa_shadows[ci * 1 + 16].x;\n    bool _1274;\n    if (!_1265)\n    {\n        _1274 = _1262 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1274 = _1265;\n    }\n    bool _1283;\n    if (!_1274)\n    {\n        _1283 = _1255.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1283 = _1274;\n    }\n    bool _1292;\n    if (!_1283)\n    {\n        _1292 = _1255.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1292 = _1283;\n    }\n    bool _1299;\n    if (!_1292)\n    {\n        _1299 = _1255.z > 1.0;\n    }\n    else\n    {\n        _1299 = _1292;\n    }\n    if (_1299)\n    {\n        return -1.0;\n    }\n    float _1308;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1308 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1308 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1327 = _1255.z - ((_1308 * (1.0 + (0.5 * _1225))) / _1207);\n    float _1336 = ((fa_shadows[ci * 1 + 20].x * min(_1225, 3.0)) * 0.5) / _1207;\n    int _1345 = int(fa_shadows[25].z + 0.5);\n    if (_1345 == 1)\n    {\n        vec2 param = _1255.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1356 = fa_shadow_depth(param, param_1);\n        return float(_1327 <= _1356);\n    }\n    float _1363 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1366 = _1345 == 2;\n    if (_1366)\n    {\n        float _1380 = clamp(((fa_shadows[25].w * _1207) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1363;\n            vec2 _1399 = fa_shadow_vogel(param_2, param_3, param_4) * _1380;\n            vec2 param_5 = _1255.xy + (_1399 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1410 = fa_shadow_depth(param_5, param_6);\n            if (_1410 < (_1327 - (length(_1399) * _1336)))\n            {\n                sum += _1410;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1327 - (sum / cnt), 0.0) * _1207) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1454 = _1366 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1454; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1454;\n        float param_9 = _1363;\n        vec2 _1473 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1255.xy + (_1473 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1484 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1327 - (length(_1473) * _1336)) <= _1484);\n    }\n    return lit / float(_1454);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1514 = int(fa_shadows[25].x + 0.5);\n    if (_1514 < 1)\n    {\n        return 1.0;\n    }\n    float _1529 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1514 - 1;\n    if (_1529 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1541 = _1514 > 1;\n    bool _1548;\n    if (_1541)\n    {\n        _1548 = _1529 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1548 = _1541;\n    }\n    if (_1548)\n    {\n        ci = 1;\n    }\n    bool _1552 = _1514 > 2;\n    bool _1559;\n    if (_1552)\n    {\n        _1559 = _1529 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1559 = _1552;\n    }\n    if (_1559)\n    {\n        ci = 2;\n    }\n    bool _1563 = _1514 > 3;\n    bool _1570;\n    if (_1563)\n    {\n        _1570 = _1529 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1570 = _1563;\n    }\n    if (_1570)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1514)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1596 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1596;\n        if (_1596 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1621;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1621 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1621 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1640 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1621, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1651 = clamp((_1529 - (fa_shadow_split_at(param_7) - _1640)) / _1640, 0.0, 1.0);\n        if (_1651 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1514)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1672 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1672;\n                if (_1672 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1651);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2031 = fa_light_sample(param, param_1);\n    vec3 _2809 = _2031.direction;\n    vec3 _2804 = _2031.color;\n    float _2806 = _2031.shadow;\n    int _2814 = _2031.type;\n    if ((_2814 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2809;\n        float _2045 = fa_shadow_factor(param_2, param_3);\n        _2806 = _2045;\n        _2804 *= _2045;\n    }\n    return LightSample(_2809, _2804, _2031.attenuation, _2806, _2031._distance, _2814);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1696 = int(fa_shadows[25].x + 0.5);\n    float _1706 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1711 = _1696 > 0;\n    bool _1720;\n    if (_1711)\n    {\n        int param = _1696 - 1;\n        _1720 = _1706 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1720 = _1711;\n    }\n    if (_1720)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1727 = _1696 > 1;\n        bool _1734;\n        if (_1727)\n        {\n            _1734 = _1706 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1734 = _1727;\n        }\n        if (_1734)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1740 = _1696 > 2;\n        bool _1747;\n        if (_1740)\n        {\n            _1747 = _1706 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1747 = _1740;\n        }\n        if (_1747)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1753 = _1696 > 3;\n        bool _1760;\n        if (_1753)\n        {\n            _1760 = _1706 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1760 = _1753;\n        }\n        if (_1760)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2687 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2687 = -_2687;\n    }\n    vec3 _2332 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n    Surface _2340 = fa_standard_surface(param_1);\n    vec3 _2726 = _2340.albedo;\n    float _2727 = _2340.alpha;\n    vec3 _2728 = _2340.normal;\n    float _2729 = _2340.metallic;\n    float _2730 = _2340.roughness;\n    float _2731 = _2340.occlusion;\n    vec3 _2732 = _2340.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n    Surface param_3 = _2340;\n    surface(param_2, param_3);\n    _2726 = param_3.albedo;\n    _2727 = param_3.alpha;\n    _2728 = param_3.normal;\n    _2729 = param_3.metallic;\n    _2730 = param_3.roughness;\n    _2731 = param_3.occlusion;\n    _2732 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2687;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2726 = param_6;\n    _2728 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2726;\n    }\n    else\n    {\n        vec3 _2378 = _2728;\n        vec3 _2379 = normalize(_2378);\n        _2728 = _2379;\n        vec3 param_8 = _2379;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n        Surface param_10 = Surface(_2726, _2727, _2728, _2729, _2730, _2731, _2732);\n        vec3 param_11 = fa_ambient_light(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _2687;\n            SurfaceInput param_16 = SurfaceInput(fa_world_pos, _2687, fa_world_tangent, fa_uv, fa_vertex_color, _2332, gl_FrontFacing);\n            Surface param_17 = Surface(_2726, _2727, _2728, _2729, _2730, _2731, _2732);\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    vec3 _2435 = result;\n    vec3 _2436 = _2435 + _2732;\n    result = _2436;\n    vec3 param_19 = _2436;\n    vec3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2445 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2453;\n    if (!_2445)\n    {\n        _2453 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2453 = _2445;\n    }\n    if (_2453)\n    {\n        vec3 _2462 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2469 = dot(_2462, fa_mesh_fs_params[9].xyz);\n        bool _2473 = fa_mesh_fs_params[9].w > 0.5;\n        float _2474;\n        if (_2473)\n        {\n            _2474 = _2469;\n        }\n        else\n        {\n            _2474 = length(_2462);\n        }\n        float _2486 = _2474 - fa_mesh_fs_params[8].x;\n        if (_2486 > 0.0)\n        {\n            float _2495 = fa_mesh_fs_params[7].w * _2486;\n            float tau = _2495 * _2495;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2511;\n                if (_2473)\n                {\n                    _2511 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2469);\n                }\n                else\n                {\n                    _2511 = fa_mesh_fs_params[0].y;\n                }\n                float _2532 = mix(_2511, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2474, 0.0, 1.0));\n                float _2536 = fa_world_pos.y - _2532;\n                float _2541 = _2532 - fa_mesh_fs_params[8].z;\n                float _2546 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2549 = _2541 <= 0.0;\n                bool _2550 = !_2549;\n                bool _2556;\n                if (_2550)\n                {\n                    _2556 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2556 = _2549;\n                }\n                float _2557;\n                if (_2556)\n                {\n                    _2557 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2557 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2541, 80.0));\n                }\n                bool _2584;\n                if (_2550)\n                {\n                    _2584 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2584 = _2549;\n                }\n                float _2585;\n                if (_2584)\n                {\n                    _2585 = fa_mesh_fs_params[8].y * _2541;\n                }\n                else\n                {\n                    _2585 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2541, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2610 = _2546 <= 0.0;\n                bool _2617;\n                if (!_2610)\n                {\n                    _2617 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2617 = _2610;\n                }\n                float _2618;\n                if (_2617)\n                {\n                    _2618 = fa_mesh_fs_params[8].y * _2546;\n                }\n                else\n                {\n                    _2618 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2546, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2645;\n                if (abs(_2536) < 0.001000000047497451305389404296875)\n                {\n                    _2645 = _2557;\n                }\n                else\n                {\n                    _2645 = (_2618 - _2585) / _2536;\n                }\n                tau += (_2486 * max(_2645, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2727);\n}\n\n",
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
            "inst_name": "_415",
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
            "inst_name": "_1155",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    vec4 _241 = (_588 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _569 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _569, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    vec4 _241 = (_588 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _569 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _569, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
