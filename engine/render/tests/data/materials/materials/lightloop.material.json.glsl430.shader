{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2528[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _505 = fa_mesh_fs_params[19].x < 0.0;\n    bool _512;\n    if (!_505)\n    {\n        _512 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _512 = _505;\n    }\n    bool _520;\n    if (!_512)\n    {\n        _520 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _520 = _512;\n    }\n    bool _527;\n    if (!_520)\n    {\n        _527 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _527 = _520;\n    }\n    bool _534;\n    if (!_527)\n    {\n        _534 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _534 = _527;\n    }\n    if (_534)\n    {\n        return vec4(0.0);\n    }\n    vec4 _544 = vec4(world_pos, 1.0);\n    float _551 = dot(fa_mesh_fs_params[16], _544);\n    if (!(_551 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _573 = vec2(dot(fa_mesh_fs_params[14], _544), dot(fa_mesh_fs_params[15], _544)) / vec2(_551);\n    int _577 = int(fa_mesh_fs_params[18].x);\n    int _581 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _581) + clamp(int(floor(((_573.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _581 - 1)) * _577)) + clamp(int(floor(((_573.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _577 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _657 = fa_cluster_texel(param);\n    return ivec2(int(_657.x), int(_657.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3326 = fa_cluster_lookup(param);\n    fa_cl_slot = _3326.x;\n    fa_cl_local = _3326.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3677 = fa_linear_to_srgb(param);\n        c = _3677;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3685 = fa_srgb_to_linear(param_1);\n            c = _3685;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _263;\n    if (i.front_facing)\n    {\n        _263 = i.world_normal;\n    }\n    else\n    {\n        _263 = -i.world_normal;\n    }\n    vec3 _287 = normalize(i.world_tangent.xyz - (_263 * dot(_263, i.world_tangent.xyz)));\n    vec3 _315 = normalize(((_287 * m.x) + ((cross(_263, _287) * i.world_tangent.w) * m.y)) + (_263 * m.z));\n    vec3 _318;\n    if (i.front_facing)\n    {\n        _318 = _315;\n    }\n    else\n    {\n        _318 = -_315;\n    }\n    return _318;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3716 = fa_tex_fix(param_2, param_3);\n    vec4 _4738 = base_t;\n    _4738.x = _3716.x;\n    _4738.y = _3716.y;\n    _4738.z = _3716.z;\n    base_t = _4738;\n    vec4 _3730 = (_4738 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4592 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3762 = fa_tex_fix(param_6, param_7);\n        vec3 _3765 = (_3762 * 2.0) - vec3(1.0);\n        vec2 _3770 = _3765.xy * fa_mesh_fs_params[6].x;\n        vec3 _4746 = _3765;\n        _4746.x = _3770.x;\n        _4746.y = _3770.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4746;\n        _4592 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3799 = fa_tex_fix(param_12, param_13);\n    vec4 _4749 = mrt;\n    _4749.x = _3799.x;\n    _4749.y = _3799.y;\n    _4749.z = _3799.z;\n    mrt = _4749;\n    vec4 _3827 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3827.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3839 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3869 = fa_tex_fix(param_20, param_21);\n    float _4597 = fa_mesh_fs_params[20].x;\n    float _4598 = fa_mesh_fs_params[20].y;\n    float _4601 = fa_mesh_fs_params[20].z;\n    float _4600 = fa_mesh_fs_params[21].w;\n    float _4603 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4597 *= _3839.y;\n            _4598 *= _3839.z;\n            _4600 *= _3827.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4601 *= mrt.x;\n            _4603 *= mrt.w;\n        }\n    }\n    return Surface(_3730.xyz, _3730.w, _4592, clamp(fa_mesh_fs_params[5].x * _3799.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3839.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3869), _4597, _4598, fa_mesh_fs_params[21].xyz, _4600, _4601, fa_mesh_fs_params[20].w, _4603, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _738 = rect.zw - rect.xy;\n    vec2 _742 = _738 * atlas;\n    vec2 _746 = ddx * _742;\n    vec2 _750 = ddy * _742;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _738), clamp(0.5 * log2(max(max(dot(_746, _746), dot(_750, _750)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _785 = fa_mesh_fs_params[10].y < 0.5;\n    bool _792;\n    if (!_785)\n    {\n        _792 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _792 = _785;\n    }\n    if (_792)\n    {\n        return;\n    }\n    vec3 _798 = dFdx(world_pos);\n    vec3 _801 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _805 = fa_cluster_texel(param);\n    int _809 = int(_805.w);\n    if (_809 < 1)\n    {\n        return;\n    }\n    int _819 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _819;\n    vec4 _823 = fa_light_texel(param_1);\n    vec2 _826 = _823.yz;\n    int _830 = int(_823.w);\n    int param_2 = _819 + 1;\n    vec4 _835 = fa_light_texel(param_2);\n    float _836 = _835.x;\n    int _842 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _846 = int(_805.z);\n    vec3 _1112;\n    for (int k = 0; k < _809; k++)\n    {\n        int _859 = _846 + k;\n        int param_3 = _830 + (_859 >> 2);\n        int _877 = (_819 + 2) + (int(fa_light_texel(param_3)[_859 & 3]) * 7);\n        int param_4 = _877 + 6;\n        vec4 _882 = fa_light_texel(param_4);\n        if (((int(_882.w + 0.5) >> _842) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _877;\n        vec4 _897 = fa_light_texel(param_5);\n        int param_6 = _877 + 1;\n        vec4 _902 = fa_light_texel(param_6);\n        int param_7 = _877 + 2;\n        vec4 _907 = fa_light_texel(param_7);\n        vec3 _910 = _897.xyz;\n        float _915 = dot(_910, world_pos) + _897.w;\n        vec3 _917 = _902.xyz;\n        float _922 = dot(_917, world_pos) + _902.w;\n        vec3 _924 = _907.xyz;\n        float _929 = dot(_924, world_pos) + _907.w;\n        bool _934 = abs(_915) > 0.5;\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_922) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        bool _950;\n        if (!_942)\n        {\n            _950 = abs(_929) > 0.5;\n        }\n        else\n        {\n            _950 = _942;\n        }\n        if (_950)\n        {\n            continue;\n        }\n        float _965 = clamp(dot(geo_normal, normalize(_924)) * _882.z, 0.0, 1.0);\n        if (_965 <= 0.0)\n        {\n            continue;\n        }\n        float _985 = (clamp((0.5 - abs(_929)) * 10.0, 0.0, 1.0) * _965) * _882.x;\n        vec2 _993 = vec2(_915 + 0.5, 0.5 - _922);\n        vec2 _1003 = vec2(dot(_910, _798), dot(_917, _798));\n        vec2 _1013 = vec2(dot(_910, _801), dot(_917, _801));\n        int param_8 = _877 + 5;\n        vec4 _1018 = fa_light_texel(param_8);\n        int param_9 = _877 + 3;\n        vec4 _1023 = fa_light_texel(param_9);\n        int param_10 = _877 + 4;\n        vec4 _1028 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1018.xyz;\n        bool _1038 = _1023.z > _1023.x;\n        if (_1038)\n        {\n            vec4 param_11 = _1023;\n            vec2 param_12 = _993;\n            vec2 param_13 = _826;\n            vec2 param_14 = _1003;\n            vec2 param_15 = _1013;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_836 > 0.5) && (_836 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1064 = fa_dc_to_linear(param_16);\n                vec4 _4648 = tx;\n                _4648.x = _1064.x;\n                _4648.y = _1064.y;\n                _4648.z = _1064.z;\n                tx = _4648;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_985 * tex_a) * _1018.w, 0.0, 1.0)));\n        if (_1028.z > _1028.x)\n        {\n            vec4 param_17 = _1028;\n            vec2 param_18 = _993;\n            vec2 param_19 = _826;\n            vec2 param_20 = _1003;\n            vec2 param_21 = _1013;\n            vec4 _1108 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_836 > 1.5)\n            {\n                vec3 param_22 = _1108.xyz;\n                vec3 _1118 = fa_dc_to_srgb(param_22);\n                _1112 = _1118;\n            }\n            else\n            {\n                _1112 = _1108.xyz;\n            }\n            vec3 _1128 = (_1112 * 2.0) - vec3(1.0);\n            vec2 _1133 = _1128.xy * _882.y;\n            vec3 _1155 = (normalize(_910) * _1133.x) + (normalize(_917) * _1133.y);\n            vec3 _1158 = normalize(normal);\n            normal = normalize(mix(_1158, normalize((_1158 * max(_1128.z, 0.0500000007450580596923828125)) + (_1155 - (_1158 * dot(_1158, _1155)))), vec3(clamp(_985 * (_1038 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _374 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _380 = fa_light_texel(param_1);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _389 = _383 < 0.5;\n    vec3 l;\n    if (_389)\n    {\n        l = normalize(_374.xyz);\n    }\n    else\n    {\n        vec3 _401 = _374.xyz - world_pos;\n        float _403 = length(_401);\n        dist = _403;\n        l = _401 / vec3(max(_403, 9.9999997473787516355514526367188e-05));\n        float _418 = _403 / max(_374.w, 0.001000000047497451305389404296875);\n        float _424 = clamp(1.0 - (_418 * _418), 0.0, 1.0);\n        atten = _424 * _424;\n        if (_383 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _438 = fa_light_texel(param_2);\n            float _448 = _438.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _454 = fa_light_texel(param_3);\n            float _455 = _454.x;\n            float cos_inner = _455;\n            if (_455 > 1.5)\n            {\n                cos_inner = mix(_448, 1.0, 0.25);\n            }\n            atten *= smoothstep(_448, cos_inner, dot(-l, normalize(_438.xyz)));\n        }\n    }\n    int _486;\n    if (_389)\n    {\n        _486 = 0;\n    }\n    else\n    {\n        _486 = (_383 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _380.xyz * atten, atten, 1.0, dist, _486);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _3511 = n < 0;\n    bool _3518;\n    if (!_3511)\n    {\n        _3518 = n >= fa_light_count();\n    }\n    else\n    {\n        _3518 = _3511;\n    }\n    if (_3518)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3526 = fa_cl_light(param);\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param_1 = _3526;\n        _3535 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3526;\n    vec3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1230;\n    if (i == 0)\n    {\n        _1230 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1246;\n        if (i == 1)\n        {\n            _1246 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1254;\n            if (i == 2)\n            {\n                _1254 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1254 = fa_shadows[24].w;\n            }\n            _1246 = _1254;\n        }\n        _1230 = _1246;\n    }\n    return _1230;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1287 = fa_shadow_depth(param, param_1);\n    float _1291;\n    if (conv.x < 0.5)\n    {\n        _1291 = _1287;\n    }\n    else\n    {\n        _1291 = (conv.y * conv.z) / (conv.z - (_1287 * (conv.z - conv.y)));\n    }\n    return _1291;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1218 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1218), sin(_1218)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1337 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1351 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1337;\n            vec2 _1370 = fa_shadow_vogel(param_3, param_4, param_5) * _1351;\n            vec2 param_6 = uv + (_1370 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1382 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1382 < (zr - (length(_1370) * plane)))\n            {\n                sum += _1382;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1426 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1426; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1426;\n        float param_11 = _1337;\n        vec2 _1445 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1445 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1445) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1426);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1487 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1492 = clamp(dot(n, l), 0.0, 1.0);\n    float _1498 = sqrt(1.0 - (_1492 * _1492));\n    float _1505 = min(_1498 / max(_1492, 0.20000000298023223876953125), 4.0);\n    float _1510;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1510 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1510 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1535 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1510 * _1498)), 1.0);\n    float _1542 = _1535.x;\n    bool _1545 = _1542 < fa_shadows[ci * 1 + 16].x;\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1542 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1535.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1572;\n    if (!_1563)\n    {\n        _1572 = _1535.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1572 = _1563;\n    }\n    bool _1579;\n    if (!_1572)\n    {\n        _1579 = _1535.z > 1.0;\n    }\n    else\n    {\n        _1579 = _1572;\n    }\n    if (_1579)\n    {\n        return -1.0;\n    }\n    float _1588;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1588 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1588 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1535.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1535.z - ((_1588 * (1.0 + (0.5 * _1505))) / _1487);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1487;\n    float param_5 = _1487 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1505, 3.0)) * 0.5) / _1487;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2015 = int(fa_shadows[25].x + 0.5);\n    if (_2015 < 1)\n    {\n        return 1.0;\n    }\n    float _2030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2015 - 1;\n    if (_2030 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2042 = _2015 > 1;\n    bool _2049;\n    if (_2042)\n    {\n        _2049 = _2030 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2049 = _2042;\n    }\n    if (_2049)\n    {\n        ci = 1;\n    }\n    bool _2053 = _2015 > 2;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2030 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 2;\n    }\n    bool _2064 = _2015 > 3;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2030 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2015)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2097;\n        if (_2097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2122 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2141 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2152 = clamp((_2030 - (fa_shadow_split_at(param_7) - _2141)) / _2141, 0.0, 1.0);\n        if (_2152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2015)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2173;\n                if (_2173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1646 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1654;\n    if (!_1646)\n    {\n        _1654 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1654 = _1646;\n    }\n    if (_1654)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1667 = fa_light_texel(param);\n    float _1668 = _1667.x;\n    if (_1668 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1677 = int(_1668 + 0.5);\n    int param_1 = _1677;\n    vec4 _1681 = fa_light_texel(param_1);\n    int param_2 = _1677 + 1;\n    vec4 _1686 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1689 = _1681.y;\n    if (_1689 > 0.0)\n    {\n        float _1706 = 1.0 - smoothstep(0.75 * _1689, _1689, length(world - fa_shadows[27].xyz));\n        fade = _1706;\n        if (_1706 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1681.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1725 = world - fa_light_texel(param_3).xyz;\n        vec3 _1728 = abs(_1725);\n        float _1730 = _1728.x;\n        float _1732 = _1728.y;\n        bool _1733 = _1730 >= _1732;\n        bool _1741;\n        if (_1733)\n        {\n            _1741 = _1730 >= _1728.z;\n        }\n        else\n        {\n            _1741 = _1733;\n        }\n        int _1742;\n        if (_1741)\n        {\n            _1742 = (_1725.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1755;\n            if (_1732 >= _1728.z)\n            {\n                _1755 = (_1725.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1755 = (_1725.z > 0.0) ? 4 : 5;\n            }\n            _1742 = _1755;\n        }\n        face = _1742;\n    }\n    int _1774 = (_1677 + 2) + (face * 6);\n    int param_4 = _1774;\n    int param_5 = _1774 + 1;\n    int param_6 = _1774 + 3;\n    vec4 _1788 = fa_light_texel(param_6);\n    int param_7 = _1774 + 4;\n    vec4 _1793 = fa_light_texel(param_7);\n    int param_8 = _1774 + 5;\n    vec4 _1798 = fa_light_texel(param_8);\n    float _1810 = _1798.x * max(dot(_1788, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1815 = clamp(dot(n, l), 0.0, 1.0);\n    float _1838 = clamp(dot(n, _1788.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1861 = min(sqrt(1.0 - (_1838 * _1838)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1788, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1864 = _1686.y;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1810;\n    }\n    vec4 _1886 = vec4(world + (n * (_1866 * sqrt(1.0 - (_1815 * _1815)))), 1.0);\n    float _1890 = dot(_1788, _1886);\n    float _1893 = _1798.y;\n    if (_1890 < _1893)\n    {\n        return 1.0;\n    }\n    vec2 _1908 = vec2(dot(fa_light_texel(param_4), _1886), dot(fa_light_texel(param_5), _1886)) / vec2(_1890);\n    float _1910 = _1908.x;\n    bool _1913 = _1910 < _1793.x;\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1910 > _1793.z;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1908.y < _1793.y;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    bool _1940;\n    if (!_1931)\n    {\n        _1940 = _1908.y > _1793.w;\n    }\n    else\n    {\n        _1940 = _1931;\n    }\n    if (_1940)\n    {\n        return 1.0;\n    }\n    float _1946 = _1686.x;\n    float _1948;\n    if (_1946 > 0.0)\n    {\n        _1948 = _1946;\n    }\n    else\n    {\n        _1948 = 1.5 * _1810;\n    }\n    vec2 param_10 = _1908;\n    vec4 param_11 = _1793;\n    float param_12 = _1890 - (_1948 * (1.0 + (0.5 * _1861)));\n    float param_13 = _1810;\n    float param_14 = 1.0;\n    float param_15 = _1798.z * 0.25;\n    float param_16 = (_1810 * min(_1861, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1893, _1798.z);\n    int param_18 = int(_1681.z + 0.5);\n    float param_19 = _1681.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3068 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3075;\n    if (!_3068)\n    {\n        _3075 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3075 = _3068;\n    }\n    if (_3075)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3088 = fa_light_texel(param);\n    float _3089 = _3088.y;\n    float len = _3089;\n    if (_3089 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3101 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3111 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3101);\n    if (_3111 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3117 = len;\n    float _3120 = min(_3117, 0.89999997615814208984375 * dist);\n    len = _3120;\n    float _3125 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3101);\n    float _3130 = _3125 + (0.5 * _3120);\n    vec3 _3136 = world + (gn * _3125);\n    float _3138 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3202;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3153 = (float(k) + _3138) * 0.083333335816860198974609375;\n        vec3 _3161 = _3136 + (l * (_3153 * len));\n        vec4 _3167 = vec4(_3161, 1.0);\n        float _3173 = dot(fa_mesh_fs_params[28], _3167);\n        if (_3173 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3193 = vec2(dot(fa_mesh_fs_params[26], _3167), dot(fa_mesh_fs_params[27], _3167)) / vec2(_3173);\n        float _3197 = _3193.x * 0.5;\n        float _3198 = _3197 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3202 = (_3193.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3202 = 0.5 - (_3193.y * 0.5);\n        }\n        bool _3218 = _3198 < 0.0;\n        bool _3225;\n        if (!_3218)\n        {\n            _3225 = _3198 >= 1.0;\n        }\n        else\n        {\n            _3225 = _3218;\n        }\n        bool _3232;\n        if (!_3225)\n        {\n            _3232 = _3202 < 0.0;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        bool _3239;\n        if (!_3232)\n        {\n            _3239 = _3202 >= 1.0;\n        }\n        else\n        {\n            _3239 = _3232;\n        }\n        if (_3239)\n        {\n            break;\n        }\n        vec4 _3258 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3198, _3202) * fa_mesh_fs_params[24].zw), 0);\n        if (_3258.w < 0.5)\n        {\n            continue;\n        }\n        float _3277 = (dot(fa_mesh_fs_params[29].xyz, _3161) + fa_mesh_fs_params[29].w) - _3258.x;\n        if ((_3277 > _3125) && (_3277 < _3130))\n        {\n            occ = max(occ, (1.0 - (_3153 * _3153)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3198, 0.5 - _3197), min(_3202, 1.0 - _3202))));\n        }\n    }\n    return 1.0 - (occ * _3111);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3353 = fa_lm.z > 0.5;\n    bool _3359;\n    if (_3353)\n    {\n        int param = li;\n        _3359 = fa_light_baked(param);\n    }\n    else\n    {\n        _3359 = _3353;\n    }\n    if (_3359)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3381 = fa_light_sample(param_2, param_3);\n    vec3 _4568 = _3381.direction;\n    vec3 _4563 = _3381.color;\n    float _4570 = _3381.attenuation;\n    float _4565 = _3381.shadow;\n    float _4572 = _3381._distance;\n    int _4573 = _3381.type;\n    bool _3384 = _4573 == 0;\n    if (_3384 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4568;\n        float _3395 = fa_shadow_factor(param_4, param_5);\n        _4565 = _3395;\n        _4563 *= _3395;\n    }\n    else\n    {\n        bool _3406 = _4573 != 0;\n        bool _3412;\n        if (_3406)\n        {\n            _3412 = _4570 > 0.0;\n        }\n        else\n        {\n            _3412 = _3406;\n        }\n        if (_3412)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4568;\n            float _3424 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4565 = _3424;\n            _4563 *= _3424;\n        }\n    }\n    bool _3434 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3440;\n    if (_3434)\n    {\n        _3440 = _4570 > 0.0;\n    }\n    else\n    {\n        _3440 = _3434;\n    }\n    if (_3440)\n    {\n        float _3447;\n        if (_3384)\n        {\n            _3447 = 1000000000.0;\n        }\n        else\n        {\n            _3447 = _4572;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _4568;\n        float param_14 = _3447;\n        float _3465 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _4565 *= _3465;\n        _4563 *= _3465;\n    }\n    return LightSample(_4568, _4563, _4570, _4565, _4572, _4573);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3485 = n < 0;\n    bool _3492;\n    if (!_3485)\n    {\n        _3492 = n >= fa_light_count();\n    }\n    else\n    {\n        _3492 = _3485;\n    }\n    if (_3492)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2453 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2461 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2464 = int(_2453);\n    int _2467 = int(_2461);\n    float _2477 = _2461 - float(_2467);\n    int _2533 = (_2464 * 9) + _2467;\n    int _2553 = ((_2464 + 1) * 9) + _2467;\n    return mix(mix(_2528[_2533], _2528[_2533 + 1], _2477), mix(_2528[_2553], _2528[_2553 + 1], _2477), _2453 - float(_2464));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4429 = false;\n    float _4430 = 1.0;\n    float _4431 = 1.0;\n    float _4432 = 1.0;\n    float _4433 = 0.0;\n    float _4434 = 0.0;\n    float _4435 = 0.0;\n    float _4436 = 0.0;\n    float _4438 = 1.0;\n    bool _4439 = false;\n    vec3 _4440 = vec3(0.0);\n    float _4441 = 1.0;\n    float _4442 = 1.0;\n    float _4443 = 1.0;\n    float _4444 = 0.0;\n    float _4445 = 0.0;\n    vec3 _4446 = vec3(1.0, 0.0, 0.0);\n    vec3 _4447 = vec3(0.0, 0.0, 1.0);\n    float _4448 = 1.0;\n    float _4449 = 1.0;\n    float _2606 = clamp(s.specular, 0.0, 1.0);\n    float _2610 = clamp(s.ior, 1.0, 3.0);\n    bool _2615 = (_2606 != 1.0) || (_2610 != 1.5);\n    bool _2625;\n    if (!_2615)\n    {\n        _2625 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2625 = _2615;\n    }\n    if (_2625)\n    {\n        float _2633 = (_2610 - 1.0) / (_2610 + 1.0);\n        f0 = mix(min(vec3(_2633 * _2633) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2606, s.albedo, vec3(metallic));\n        _4430 = mix(_2606, 1.0, metallic);\n        _4429 = true;\n    }\n    float _2661 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2661 > 0.0)\n    {\n        float _2669 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4433 = _2661;\n        _4434 = _2669;\n        float _2676 = _2669 * _2669;\n        _4435 = _2676;\n        _4436 = _2676 * _2676;\n        float _2688 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4438 = _2688;\n        _4431 = 1.0 - (_2661 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2688, 0.0, 1.0), 5.0))));\n        _4429 = true;\n    }\n    vec3 _2708 = max(s.sheen_color, vec3(0.0));\n    float _2717 = max(_2708.x, max(_2708.y, _2708.z));\n    if (_2717 > 0.0)\n    {\n        float _2725 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4439 = true;\n        _4440 = _2708;\n        _4441 = _2725;\n        _4442 = _2725 * _2725;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2725;\n        float _2742 = fa_sheen_albedo(param, param_1);\n        _4444 = _2742;\n        _4443 = 1.0 - min(_2717 * _2742, 1.0);\n        _4429 = true;\n    }\n    _4432 = _4431 * _4443;\n    float _2761 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2761 != 0.0)\n    {\n        vec3 _2776 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2776;\n        if (dot(_2776, _2776) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2789 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2789.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2789.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2789.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2793 = t;\n        vec3 _2794 = normalize(_2793);\n        t = _2794;\n        vec3 _2819 = normalize((_2794 * cos(s.anisotropy_rotation)) + ((cross(n, _2794) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4446 = _2819;\n        _4447 = cross(n, _2819);\n        float _2829 = roughness * roughness;\n        float _2835 = mix(_2829, 1.0, _2761 * _2761);\n        bool _2837 = _2761 > 0.0;\n        _4448 = _2837 ? _2835 : _2829;\n        _4449 = _2837 ? _2829 : _2835;\n        _4445 = _2761;\n        _4429 = true;\n    }\n    return FaLayers(_4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, i.world_normal, _4438, _4439, _4440, _4441, _4442, _4443, _4444, _4445, _4446, _4447, _4448, _4449);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2385 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2388 = _2385.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2388 * _2388, exp2((-9.27999973297119140625) * ndv)) * _2388) + _2385.y)) + _2385.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2309 = rough * rough;\n    float _2339 = 0.60000002384185791015625 * _2309;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2309)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2339, 0.0500000007450580596923828125 + _2339, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2309 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2870;\n        if (L.aniso >= 0.0)\n        {\n            _2870 = L.b;\n        }\n        else\n        {\n            _2870 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2870, v), _2870), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2903 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2903.x) + (vec3(L.f90) * _2903.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2958 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2958.x) + _2958.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2427 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2427.x) + vec3(_2427.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2997 = clamp(s.metallic, 0.0, 1.0);\n    float _3001 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3008 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2997));\n    vec3 f0 = _3008;\n    vec3 _3012 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3012;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2997;\n    float param_5 = _3001;\n    vec3 param_6 = _3008;\n    FaLayers _3029 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3029.on)\n    {\n        FaLayers param_7 = _3029;\n        vec3 param_8 = _3012;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3001;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3012;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3001;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3573 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3573 > bestPower)\n        {\n            bestPower = _3573;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3602 = fa_light(param_2, param_3);\n        float _3610;\n        if (dot(s.normal, _3602.direction) > 0.5)\n        {\n            _3610 = 1.0;\n        }\n        else\n        {\n            _3610 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _3602.color) * _3610);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2197 = int(fa_shadows[25].x + 0.5);\n    float _2207 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2212 = _2197 > 0;\n    bool _2221;\n    if (_2212)\n    {\n        int param = _2197 - 1;\n        _2221 = _2207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2221 = _2212;\n    }\n    if (_2221)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2228 = _2197 > 1;\n        bool _2235;\n        if (_2228)\n        {\n            _2235 = _2207 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2235 = _2228;\n        }\n        if (_2235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2241 = _2197 > 2;\n        bool _2248;\n        if (_2241)\n        {\n            _2248 = _2207 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2248 = _2241;\n        }\n        if (_2248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2254 = _2197 > 3;\n        bool _2261;\n        if (_2254)\n        {\n            _2261 = _2207 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2261 = _2254;\n        }\n        if (_2261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4303 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4303 = -_4303;\n    }\n    vec3 _3990 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n    Surface _3998 = fa_standard_surface(param_1);\n    vec3 _4334 = _3998.albedo;\n    float _4335 = _3998.alpha;\n    vec3 _4336 = _3998.normal;\n    float _4337 = _3998.metallic;\n    float _4338 = _3998.roughness;\n    float _4339 = _3998.occlusion;\n    vec3 _4340 = _3998.emission;\n    float _4341 = _3998.clearcoat;\n    float _4342 = _3998.clearcoat_roughness;\n    vec3 _4343 = _3998.sheen_color;\n    float _4344 = _3998.sheen_roughness;\n    float _4345 = _3998.anisotropy;\n    float _4346 = _3998.anisotropy_rotation;\n    float _4347 = _3998.specular;\n    float _4348 = _3998.ior;\n    vec3 _4349 = _3998.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n    Surface param_3 = _3998;\n    surface(param_2, param_3);\n    _4334 = param_3.albedo;\n    _4335 = param_3.alpha;\n    _4336 = param_3.normal;\n    _4337 = param_3.metallic;\n    _4338 = param_3.roughness;\n    _4339 = param_3.occlusion;\n    _4340 = param_3.emission;\n    _4341 = param_3.clearcoat;\n    _4342 = param_3.clearcoat_roughness;\n    _4343 = param_3.sheen_color;\n    _4344 = param_3.sheen_roughness;\n    _4345 = param_3.anisotropy;\n    _4346 = param_3.anisotropy_rotation;\n    _4347 = param_3.specular;\n    _4348 = param_3.ior;\n    _4349 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4303;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4334 = param_6;\n    _4336 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4334;\n    }\n    else\n    {\n        vec3 _4036 = _4336;\n        vec3 _4037 = normalize(_4036);\n        _4336 = _4037;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n        Surface param_9 = Surface(_4334, _4335, _4037, _4337, _4338, _4339, _4340, _4341, _4342, _4343, _4344, _4345, _4346, _4347, _4348, _4349);\n        result = lighting(param_8, param_9);\n    }\n    vec3 _4052 = result;\n    vec3 _4053 = _4052 + _4340;\n    result = _4053;\n    vec3 param_10 = _4053;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4062 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4069;\n    if (!_4062)\n    {\n        _4069 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4069 = _4062;\n    }\n    if (_4069)\n    {\n        vec3 _4078 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4084 = dot(_4078, fa_mesh_fs_params[9].xyz);\n        bool _4088 = fa_mesh_fs_params[9].w > 0.5;\n        float _4089;\n        if (_4088)\n        {\n            _4089 = _4084;\n        }\n        else\n        {\n            _4089 = length(_4078);\n        }\n        float _4101 = _4089 - fa_mesh_fs_params[8].x;\n        if (_4101 > 0.0)\n        {\n            float _4110 = fa_mesh_fs_params[7].w * _4101;\n            float tau = _4110 * _4110;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4126;\n                if (_4088)\n                {\n                    _4126 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4084);\n                }\n                else\n                {\n                    _4126 = fa_mesh_fs_params[0].y;\n                }\n                float _4147 = mix(_4126, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4089, 0.0, 1.0));\n                float _4151 = fa_world_pos.y - _4147;\n                float _4156 = _4147 - fa_mesh_fs_params[8].z;\n                float _4161 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4164 = _4156 <= 0.0;\n                bool _4165 = !_4164;\n                bool _4171;\n                if (_4165)\n                {\n                    _4171 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4171 = _4164;\n                }\n                float _4172;\n                if (_4171)\n                {\n                    _4172 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4172 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4156, 80.0));\n                }\n                bool _4199;\n                if (_4165)\n                {\n                    _4199 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4199 = _4164;\n                }\n                float _4200;\n                if (_4199)\n                {\n                    _4200 = fa_mesh_fs_params[8].y * _4156;\n                }\n                else\n                {\n                    _4200 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4156, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4225 = _4161 <= 0.0;\n                bool _4232;\n                if (!_4225)\n                {\n                    _4232 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4232 = _4225;\n                }\n                float _4233;\n                if (_4232)\n                {\n                    _4233 = fa_mesh_fs_params[8].y * _4161;\n                }\n                else\n                {\n                    _4233 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4161, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4260;\n                if (abs(_4151) < 0.001000000047497451305389404296875)\n                {\n                    _4260 = _4172;\n                }\n                else\n                {\n                    _4260 = (_4233 - _4200) / _4151;\n                }\n                tau += (_4101 * max(_4260, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4335);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_500",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_1240",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3616",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2528[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _505 = fa_mesh_fs_params[19].x < 0.0;\n    bool _512;\n    if (!_505)\n    {\n        _512 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _512 = _505;\n    }\n    bool _520;\n    if (!_512)\n    {\n        _520 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _520 = _512;\n    }\n    bool _527;\n    if (!_520)\n    {\n        _527 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _527 = _520;\n    }\n    bool _534;\n    if (!_527)\n    {\n        _534 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _534 = _527;\n    }\n    if (_534)\n    {\n        return vec4(0.0);\n    }\n    vec4 _544 = vec4(world_pos, 1.0);\n    float _551 = dot(fa_mesh_fs_params[16], _544);\n    if (!(_551 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _573 = vec2(dot(fa_mesh_fs_params[14], _544), dot(fa_mesh_fs_params[15], _544)) / vec2(_551);\n    int _577 = int(fa_mesh_fs_params[18].x);\n    int _581 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _581) + clamp(int(floor(((_573.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _581 - 1)) * _577)) + clamp(int(floor(((_573.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _577 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _657 = fa_cluster_texel(param);\n    return ivec2(int(_657.x), int(_657.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3326 = fa_cluster_lookup(param);\n    fa_cl_slot = _3326.x;\n    fa_cl_local = _3326.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3677 = fa_linear_to_srgb(param);\n        c = _3677;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3685 = fa_srgb_to_linear(param_1);\n            c = _3685;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _263;\n    if (i.front_facing)\n    {\n        _263 = i.world_normal;\n    }\n    else\n    {\n        _263 = -i.world_normal;\n    }\n    vec3 _287 = normalize(i.world_tangent.xyz - (_263 * dot(_263, i.world_tangent.xyz)));\n    vec3 _315 = normalize(((_287 * m.x) + ((cross(_263, _287) * i.world_tangent.w) * m.y)) + (_263 * m.z));\n    vec3 _318;\n    if (i.front_facing)\n    {\n        _318 = _315;\n    }\n    else\n    {\n        _318 = -_315;\n    }\n    return _318;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3716 = fa_tex_fix(param_2, param_3);\n    vec4 _4738 = base_t;\n    _4738.x = _3716.x;\n    _4738.y = _3716.y;\n    _4738.z = _3716.z;\n    base_t = _4738;\n    vec4 _3730 = (_4738 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4592 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3762 = fa_tex_fix(param_6, param_7);\n        vec3 _3765 = (_3762 * 2.0) - vec3(1.0);\n        vec2 _3770 = _3765.xy * fa_mesh_fs_params[6].x;\n        vec3 _4746 = _3765;\n        _4746.x = _3770.x;\n        _4746.y = _3770.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4746;\n        _4592 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3799 = fa_tex_fix(param_12, param_13);\n    vec4 _4749 = mrt;\n    _4749.x = _3799.x;\n    _4749.y = _3799.y;\n    _4749.z = _3799.z;\n    mrt = _4749;\n    vec4 _3827 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3827.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3839 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3869 = fa_tex_fix(param_20, param_21);\n    float _4597 = fa_mesh_fs_params[20].x;\n    float _4598 = fa_mesh_fs_params[20].y;\n    float _4601 = fa_mesh_fs_params[20].z;\n    float _4600 = fa_mesh_fs_params[21].w;\n    float _4603 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4597 *= _3839.y;\n            _4598 *= _3839.z;\n            _4600 *= _3827.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4601 *= mrt.x;\n            _4603 *= mrt.w;\n        }\n    }\n    return Surface(_3730.xyz, _3730.w, _4592, clamp(fa_mesh_fs_params[5].x * _3799.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3799.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3839.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3869), _4597, _4598, fa_mesh_fs_params[21].xyz, _4600, _4601, fa_mesh_fs_params[20].w, _4603, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _738 = rect.zw - rect.xy;\n    vec2 _742 = _738 * atlas;\n    vec2 _746 = ddx * _742;\n    vec2 _750 = ddy * _742;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _738), clamp(0.5 * log2(max(max(dot(_746, _746), dot(_750, _750)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _785 = fa_mesh_fs_params[10].y < 0.5;\n    bool _792;\n    if (!_785)\n    {\n        _792 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _792 = _785;\n    }\n    if (_792)\n    {\n        return;\n    }\n    vec3 _798 = dFdx(world_pos);\n    vec3 _801 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _805 = fa_cluster_texel(param);\n    int _809 = int(_805.w);\n    if (_809 < 1)\n    {\n        return;\n    }\n    int _819 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _819;\n    vec4 _823 = fa_light_texel(param_1);\n    vec2 _826 = _823.yz;\n    int _830 = int(_823.w);\n    int param_2 = _819 + 1;\n    vec4 _835 = fa_light_texel(param_2);\n    float _836 = _835.x;\n    int _842 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _846 = int(_805.z);\n    vec3 _1112;\n    for (int k = 0; k < _809; k++)\n    {\n        int _859 = _846 + k;\n        int param_3 = _830 + (_859 >> 2);\n        int _877 = (_819 + 2) + (int(fa_light_texel(param_3)[_859 & 3]) * 7);\n        int param_4 = _877 + 6;\n        vec4 _882 = fa_light_texel(param_4);\n        if (((int(_882.w + 0.5) >> _842) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _877;\n        vec4 _897 = fa_light_texel(param_5);\n        int param_6 = _877 + 1;\n        vec4 _902 = fa_light_texel(param_6);\n        int param_7 = _877 + 2;\n        vec4 _907 = fa_light_texel(param_7);\n        vec3 _910 = _897.xyz;\n        float _915 = dot(_910, world_pos) + _897.w;\n        vec3 _917 = _902.xyz;\n        float _922 = dot(_917, world_pos) + _902.w;\n        vec3 _924 = _907.xyz;\n        float _929 = dot(_924, world_pos) + _907.w;\n        bool _934 = abs(_915) > 0.5;\n        bool _942;\n        if (!_934)\n        {\n            _942 = abs(_922) > 0.5;\n        }\n        else\n        {\n            _942 = _934;\n        }\n        bool _950;\n        if (!_942)\n        {\n            _950 = abs(_929) > 0.5;\n        }\n        else\n        {\n            _950 = _942;\n        }\n        if (_950)\n        {\n            continue;\n        }\n        float _965 = clamp(dot(geo_normal, normalize(_924)) * _882.z, 0.0, 1.0);\n        if (_965 <= 0.0)\n        {\n            continue;\n        }\n        float _985 = (clamp((0.5 - abs(_929)) * 10.0, 0.0, 1.0) * _965) * _882.x;\n        vec2 _993 = vec2(_915 + 0.5, 0.5 - _922);\n        vec2 _1003 = vec2(dot(_910, _798), dot(_917, _798));\n        vec2 _1013 = vec2(dot(_910, _801), dot(_917, _801));\n        int param_8 = _877 + 5;\n        vec4 _1018 = fa_light_texel(param_8);\n        int param_9 = _877 + 3;\n        vec4 _1023 = fa_light_texel(param_9);\n        int param_10 = _877 + 4;\n        vec4 _1028 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1018.xyz;\n        bool _1038 = _1023.z > _1023.x;\n        if (_1038)\n        {\n            vec4 param_11 = _1023;\n            vec2 param_12 = _993;\n            vec2 param_13 = _826;\n            vec2 param_14 = _1003;\n            vec2 param_15 = _1013;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_836 > 0.5) && (_836 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1064 = fa_dc_to_linear(param_16);\n                vec4 _4648 = tx;\n                _4648.x = _1064.x;\n                _4648.y = _1064.y;\n                _4648.z = _1064.z;\n                tx = _4648;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_985 * tex_a) * _1018.w, 0.0, 1.0)));\n        if (_1028.z > _1028.x)\n        {\n            vec4 param_17 = _1028;\n            vec2 param_18 = _993;\n            vec2 param_19 = _826;\n            vec2 param_20 = _1003;\n            vec2 param_21 = _1013;\n            vec4 _1108 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_836 > 1.5)\n            {\n                vec3 param_22 = _1108.xyz;\n                vec3 _1118 = fa_dc_to_srgb(param_22);\n                _1112 = _1118;\n            }\n            else\n            {\n                _1112 = _1108.xyz;\n            }\n            vec3 _1128 = (_1112 * 2.0) - vec3(1.0);\n            vec2 _1133 = _1128.xy * _882.y;\n            vec3 _1155 = (normalize(_910) * _1133.x) + (normalize(_917) * _1133.y);\n            vec3 _1158 = normalize(normal);\n            normal = normalize(mix(_1158, normalize((_1158 * max(_1128.z, 0.0500000007450580596923828125)) + (_1155 - (_1158 * dot(_1158, _1155)))), vec3(clamp(_985 * (_1038 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _374 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _380 = fa_light_texel(param_1);\n    float _383 = _380.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _389 = _383 < 0.5;\n    vec3 l;\n    if (_389)\n    {\n        l = normalize(_374.xyz);\n    }\n    else\n    {\n        vec3 _401 = _374.xyz - world_pos;\n        float _403 = length(_401);\n        dist = _403;\n        l = _401 / vec3(max(_403, 9.9999997473787516355514526367188e-05));\n        float _418 = _403 / max(_374.w, 0.001000000047497451305389404296875);\n        float _424 = clamp(1.0 - (_418 * _418), 0.0, 1.0);\n        atten = _424 * _424;\n        if (_383 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _438 = fa_light_texel(param_2);\n            float _448 = _438.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _454 = fa_light_texel(param_3);\n            float _455 = _454.x;\n            float cos_inner = _455;\n            if (_455 > 1.5)\n            {\n                cos_inner = mix(_448, 1.0, 0.25);\n            }\n            atten *= smoothstep(_448, cos_inner, dot(-l, normalize(_438.xyz)));\n        }\n    }\n    int _486;\n    if (_389)\n    {\n        _486 = 0;\n    }\n    else\n    {\n        _486 = (_383 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _380.xyz * atten, atten, 1.0, dist, _486);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _3511 = n < 0;\n    bool _3518;\n    if (!_3511)\n    {\n        _3518 = n >= fa_light_count();\n    }\n    else\n    {\n        _3518 = _3511;\n    }\n    if (_3518)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _3526 = fa_cl_light(param);\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param_1 = _3526;\n        _3535 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _3526;\n    vec3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1230;\n    if (i == 0)\n    {\n        _1230 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1246;\n        if (i == 1)\n        {\n            _1246 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1254;\n            if (i == 2)\n            {\n                _1254 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1254 = fa_shadows[24].w;\n            }\n            _1246 = _1254;\n        }\n        _1230 = _1246;\n    }\n    return _1230;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1287 = fa_shadow_depth(param, param_1);\n    float _1291;\n    if (conv.x < 0.5)\n    {\n        _1291 = _1287;\n    }\n    else\n    {\n        _1291 = (conv.y * conv.z) / (conv.z - (_1287 * (conv.z - conv.y)));\n    }\n    return _1291;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1218 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1218), sin(_1218)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1337 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1351 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1337;\n            vec2 _1370 = fa_shadow_vogel(param_3, param_4, param_5) * _1351;\n            vec2 param_6 = uv + (_1370 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1382 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1382 < (zr - (length(_1370) * plane)))\n            {\n                sum += _1382;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1426 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1426; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1426;\n        float param_11 = _1337;\n        vec2 _1445 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1445 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1445) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1426);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1487 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1492 = clamp(dot(n, l), 0.0, 1.0);\n    float _1498 = sqrt(1.0 - (_1492 * _1492));\n    float _1505 = min(_1498 / max(_1492, 0.20000000298023223876953125), 4.0);\n    float _1510;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1510 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1510 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1535 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1510 * _1498)), 1.0);\n    float _1542 = _1535.x;\n    bool _1545 = _1542 < fa_shadows[ci * 1 + 16].x;\n    bool _1554;\n    if (!_1545)\n    {\n        _1554 = _1542 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1554 = _1545;\n    }\n    bool _1563;\n    if (!_1554)\n    {\n        _1563 = _1535.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1563 = _1554;\n    }\n    bool _1572;\n    if (!_1563)\n    {\n        _1572 = _1535.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1572 = _1563;\n    }\n    bool _1579;\n    if (!_1572)\n    {\n        _1579 = _1535.z > 1.0;\n    }\n    else\n    {\n        _1579 = _1572;\n    }\n    if (_1579)\n    {\n        return -1.0;\n    }\n    float _1588;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1588 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1588 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1535.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1535.z - ((_1588 * (1.0 + (0.5 * _1505))) / _1487);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1487;\n    float param_5 = _1487 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1505, 3.0)) * 0.5) / _1487;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2015 = int(fa_shadows[25].x + 0.5);\n    if (_2015 < 1)\n    {\n        return 1.0;\n    }\n    float _2030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2015 - 1;\n    if (_2030 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2042 = _2015 > 1;\n    bool _2049;\n    if (_2042)\n    {\n        _2049 = _2030 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2049 = _2042;\n    }\n    if (_2049)\n    {\n        ci = 1;\n    }\n    bool _2053 = _2015 > 2;\n    bool _2060;\n    if (_2053)\n    {\n        _2060 = _2030 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2060 = _2053;\n    }\n    if (_2060)\n    {\n        ci = 2;\n    }\n    bool _2064 = _2015 > 3;\n    bool _2071;\n    if (_2064)\n    {\n        _2071 = _2030 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2071 = _2064;\n    }\n    if (_2071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2015)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2097;\n        if (_2097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2122 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2141 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2152 = clamp((_2030 - (fa_shadow_split_at(param_7) - _2141)) / _2141, 0.0, 1.0);\n        if (_2152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2015)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2173;\n                if (_2173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1646 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1654;\n    if (!_1646)\n    {\n        _1654 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1654 = _1646;\n    }\n    if (_1654)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1667 = fa_light_texel(param);\n    float _1668 = _1667.x;\n    if (_1668 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1677 = int(_1668 + 0.5);\n    int param_1 = _1677;\n    vec4 _1681 = fa_light_texel(param_1);\n    int param_2 = _1677 + 1;\n    vec4 _1686 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1689 = _1681.y;\n    if (_1689 > 0.0)\n    {\n        float _1706 = 1.0 - smoothstep(0.75 * _1689, _1689, length(world - fa_shadows[27].xyz));\n        fade = _1706;\n        if (_1706 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1681.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1725 = world - fa_light_texel(param_3).xyz;\n        vec3 _1728 = abs(_1725);\n        float _1730 = _1728.x;\n        float _1732 = _1728.y;\n        bool _1733 = _1730 >= _1732;\n        bool _1741;\n        if (_1733)\n        {\n            _1741 = _1730 >= _1728.z;\n        }\n        else\n        {\n            _1741 = _1733;\n        }\n        int _1742;\n        if (_1741)\n        {\n            _1742 = (_1725.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1755;\n            if (_1732 >= _1728.z)\n            {\n                _1755 = (_1725.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1755 = (_1725.z > 0.0) ? 4 : 5;\n            }\n            _1742 = _1755;\n        }\n        face = _1742;\n    }\n    int _1774 = (_1677 + 2) + (face * 6);\n    int param_4 = _1774;\n    int param_5 = _1774 + 1;\n    int param_6 = _1774 + 3;\n    vec4 _1788 = fa_light_texel(param_6);\n    int param_7 = _1774 + 4;\n    vec4 _1793 = fa_light_texel(param_7);\n    int param_8 = _1774 + 5;\n    vec4 _1798 = fa_light_texel(param_8);\n    float _1810 = _1798.x * max(dot(_1788, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1815 = clamp(dot(n, l), 0.0, 1.0);\n    float _1838 = clamp(dot(n, _1788.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1861 = min(sqrt(1.0 - (_1838 * _1838)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1788, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1864 = _1686.y;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1810;\n    }\n    vec4 _1886 = vec4(world + (n * (_1866 * sqrt(1.0 - (_1815 * _1815)))), 1.0);\n    float _1890 = dot(_1788, _1886);\n    float _1893 = _1798.y;\n    if (_1890 < _1893)\n    {\n        return 1.0;\n    }\n    vec2 _1908 = vec2(dot(fa_light_texel(param_4), _1886), dot(fa_light_texel(param_5), _1886)) / vec2(_1890);\n    float _1910 = _1908.x;\n    bool _1913 = _1910 < _1793.x;\n    bool _1922;\n    if (!_1913)\n    {\n        _1922 = _1910 > _1793.z;\n    }\n    else\n    {\n        _1922 = _1913;\n    }\n    bool _1931;\n    if (!_1922)\n    {\n        _1931 = _1908.y < _1793.y;\n    }\n    else\n    {\n        _1931 = _1922;\n    }\n    bool _1940;\n    if (!_1931)\n    {\n        _1940 = _1908.y > _1793.w;\n    }\n    else\n    {\n        _1940 = _1931;\n    }\n    if (_1940)\n    {\n        return 1.0;\n    }\n    float _1946 = _1686.x;\n    float _1948;\n    if (_1946 > 0.0)\n    {\n        _1948 = _1946;\n    }\n    else\n    {\n        _1948 = 1.5 * _1810;\n    }\n    vec2 param_10 = _1908;\n    vec4 param_11 = _1793;\n    float param_12 = _1890 - (_1948 * (1.0 + (0.5 * _1861)));\n    float param_13 = _1810;\n    float param_14 = 1.0;\n    float param_15 = _1798.z * 0.25;\n    float param_16 = (_1810 * min(_1861, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1893, _1798.z);\n    int param_18 = int(_1681.z + 0.5);\n    float param_19 = _1681.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3068 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3075;\n    if (!_3068)\n    {\n        _3075 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3075 = _3068;\n    }\n    if (_3075)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3088 = fa_light_texel(param);\n    float _3089 = _3088.y;\n    float len = _3089;\n    if (_3089 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3101 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3111 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3101);\n    if (_3111 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3117 = len;\n    float _3120 = min(_3117, 0.89999997615814208984375 * dist);\n    len = _3120;\n    float _3125 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3101);\n    float _3130 = _3125 + (0.5 * _3120);\n    vec3 _3136 = world + (gn * _3125);\n    float _3138 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3202;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3153 = (float(k) + _3138) * 0.083333335816860198974609375;\n        vec3 _3161 = _3136 + (l * (_3153 * len));\n        vec4 _3167 = vec4(_3161, 1.0);\n        float _3173 = dot(fa_mesh_fs_params[28], _3167);\n        if (_3173 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3193 = vec2(dot(fa_mesh_fs_params[26], _3167), dot(fa_mesh_fs_params[27], _3167)) / vec2(_3173);\n        float _3197 = _3193.x * 0.5;\n        float _3198 = _3197 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3202 = (_3193.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3202 = 0.5 - (_3193.y * 0.5);\n        }\n        bool _3218 = _3198 < 0.0;\n        bool _3225;\n        if (!_3218)\n        {\n            _3225 = _3198 >= 1.0;\n        }\n        else\n        {\n            _3225 = _3218;\n        }\n        bool _3232;\n        if (!_3225)\n        {\n            _3232 = _3202 < 0.0;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        bool _3239;\n        if (!_3232)\n        {\n            _3239 = _3202 >= 1.0;\n        }\n        else\n        {\n            _3239 = _3232;\n        }\n        if (_3239)\n        {\n            break;\n        }\n        vec4 _3258 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3198, _3202) * fa_mesh_fs_params[24].zw), 0);\n        if (_3258.w < 0.5)\n        {\n            continue;\n        }\n        float _3277 = (dot(fa_mesh_fs_params[29].xyz, _3161) + fa_mesh_fs_params[29].w) - _3258.x;\n        if ((_3277 > _3125) && (_3277 < _3130))\n        {\n            occ = max(occ, (1.0 - (_3153 * _3153)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3198, 0.5 - _3197), min(_3202, 1.0 - _3202))));\n        }\n    }\n    return 1.0 - (occ * _3111);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3353 = fa_lm.z > 0.5;\n    bool _3359;\n    if (_3353)\n    {\n        int param = li;\n        _3359 = fa_light_baked(param);\n    }\n    else\n    {\n        _3359 = _3353;\n    }\n    if (_3359)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3381 = fa_light_sample(param_2, param_3);\n    vec3 _4568 = _3381.direction;\n    vec3 _4563 = _3381.color;\n    float _4570 = _3381.attenuation;\n    float _4565 = _3381.shadow;\n    float _4572 = _3381._distance;\n    int _4573 = _3381.type;\n    bool _3384 = _4573 == 0;\n    if (_3384 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4568;\n        float _3395 = fa_shadow_factor(param_4, param_5);\n        _4565 = _3395;\n        _4563 *= _3395;\n    }\n    else\n    {\n        bool _3406 = _4573 != 0;\n        bool _3412;\n        if (_3406)\n        {\n            _3412 = _4570 > 0.0;\n        }\n        else\n        {\n            _3412 = _3406;\n        }\n        if (_3412)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4568;\n            float _3424 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4565 = _3424;\n            _4563 *= _3424;\n        }\n    }\n    bool _3434 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3440;\n    if (_3434)\n    {\n        _3440 = _4570 > 0.0;\n    }\n    else\n    {\n        _3440 = _3434;\n    }\n    if (_3440)\n    {\n        float _3447;\n        if (_3384)\n        {\n            _3447 = 1000000000.0;\n        }\n        else\n        {\n            _3447 = _4572;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _4568;\n        float param_14 = _3447;\n        float _3465 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _4565 *= _3465;\n        _4563 *= _3465;\n    }\n    return LightSample(_4568, _4563, _4570, _4565, _4572, _4573);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _3485 = n < 0;\n    bool _3492;\n    if (!_3485)\n    {\n        _3492 = n >= fa_light_count();\n    }\n    else\n    {\n        _3492 = _3485;\n    }\n    if (_3492)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2453 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2461 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2464 = int(_2453);\n    int _2467 = int(_2461);\n    float _2477 = _2461 - float(_2467);\n    int _2533 = (_2464 * 9) + _2467;\n    int _2553 = ((_2464 + 1) * 9) + _2467;\n    return mix(mix(_2528[_2533], _2528[_2533 + 1], _2477), mix(_2528[_2553], _2528[_2553 + 1], _2477), _2453 - float(_2464));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4429 = false;\n    float _4430 = 1.0;\n    float _4431 = 1.0;\n    float _4432 = 1.0;\n    float _4433 = 0.0;\n    float _4434 = 0.0;\n    float _4435 = 0.0;\n    float _4436 = 0.0;\n    float _4438 = 1.0;\n    bool _4439 = false;\n    vec3 _4440 = vec3(0.0);\n    float _4441 = 1.0;\n    float _4442 = 1.0;\n    float _4443 = 1.0;\n    float _4444 = 0.0;\n    float _4445 = 0.0;\n    vec3 _4446 = vec3(1.0, 0.0, 0.0);\n    vec3 _4447 = vec3(0.0, 0.0, 1.0);\n    float _4448 = 1.0;\n    float _4449 = 1.0;\n    float _2606 = clamp(s.specular, 0.0, 1.0);\n    float _2610 = clamp(s.ior, 1.0, 3.0);\n    bool _2615 = (_2606 != 1.0) || (_2610 != 1.5);\n    bool _2625;\n    if (!_2615)\n    {\n        _2625 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2625 = _2615;\n    }\n    if (_2625)\n    {\n        float _2633 = (_2610 - 1.0) / (_2610 + 1.0);\n        f0 = mix(min(vec3(_2633 * _2633) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2606, s.albedo, vec3(metallic));\n        _4430 = mix(_2606, 1.0, metallic);\n        _4429 = true;\n    }\n    float _2661 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2661 > 0.0)\n    {\n        float _2669 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4433 = _2661;\n        _4434 = _2669;\n        float _2676 = _2669 * _2669;\n        _4435 = _2676;\n        _4436 = _2676 * _2676;\n        float _2688 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4438 = _2688;\n        _4431 = 1.0 - (_2661 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2688, 0.0, 1.0), 5.0))));\n        _4429 = true;\n    }\n    vec3 _2708 = max(s.sheen_color, vec3(0.0));\n    float _2717 = max(_2708.x, max(_2708.y, _2708.z));\n    if (_2717 > 0.0)\n    {\n        float _2725 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4439 = true;\n        _4440 = _2708;\n        _4441 = _2725;\n        _4442 = _2725 * _2725;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2725;\n        float _2742 = fa_sheen_albedo(param, param_1);\n        _4444 = _2742;\n        _4443 = 1.0 - min(_2717 * _2742, 1.0);\n        _4429 = true;\n    }\n    _4432 = _4431 * _4443;\n    float _2761 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2761 != 0.0)\n    {\n        vec3 _2776 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2776;\n        if (dot(_2776, _2776) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2789 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2789.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2789.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2789.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2793 = t;\n        vec3 _2794 = normalize(_2793);\n        t = _2794;\n        vec3 _2819 = normalize((_2794 * cos(s.anisotropy_rotation)) + ((cross(n, _2794) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4446 = _2819;\n        _4447 = cross(n, _2819);\n        float _2829 = roughness * roughness;\n        float _2835 = mix(_2829, 1.0, _2761 * _2761);\n        bool _2837 = _2761 > 0.0;\n        _4448 = _2837 ? _2835 : _2829;\n        _4449 = _2837 ? _2829 : _2835;\n        _4445 = _2761;\n        _4429 = true;\n    }\n    return FaLayers(_4429, _4430, _4431, _4432, _4433, _4434, _4435, _4436, i.world_normal, _4438, _4439, _4440, _4441, _4442, _4443, _4444, _4445, _4446, _4447, _4448, _4449);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2385 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2388 = _2385.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2388 * _2388, exp2((-9.27999973297119140625) * ndv)) * _2388) + _2385.y)) + _2385.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2309 = rough * rough;\n    float _2339 = 0.60000002384185791015625 * _2309;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2309)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2339, 0.0500000007450580596923828125 + _2339, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2309 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2870;\n        if (L.aniso >= 0.0)\n        {\n            _2870 = L.b;\n        }\n        else\n        {\n            _2870 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2870, v), _2870), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2903 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2903.x) + (vec3(L.f90) * _2903.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2958 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2958.x) + _2958.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2427 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2427.x) + vec3(_2427.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2997 = clamp(s.metallic, 0.0, 1.0);\n    float _3001 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3008 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2997));\n    vec3 f0 = _3008;\n    vec3 _3012 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3012;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2997;\n    float param_5 = _3001;\n    vec3 param_6 = _3008;\n    FaLayers _3029 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3029.on)\n    {\n        FaLayers param_7 = _3029;\n        vec3 param_8 = _3012;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3001;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3012;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3001;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _3573 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_3573 > bestPower)\n        {\n            bestPower = _3573;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _3602 = fa_light(param_2, param_3);\n        float _3610;\n        if (dot(s.normal, _3602.direction) > 0.5)\n        {\n            _3610 = 1.0;\n        }\n        else\n        {\n            _3610 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _3602.color) * _3610);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2197 = int(fa_shadows[25].x + 0.5);\n    float _2207 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2212 = _2197 > 0;\n    bool _2221;\n    if (_2212)\n    {\n        int param = _2197 - 1;\n        _2221 = _2207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2221 = _2212;\n    }\n    if (_2221)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2228 = _2197 > 1;\n        bool _2235;\n        if (_2228)\n        {\n            _2235 = _2207 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2235 = _2228;\n        }\n        if (_2235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2241 = _2197 > 2;\n        bool _2248;\n        if (_2241)\n        {\n            _2248 = _2207 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2248 = _2241;\n        }\n        if (_2248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2254 = _2197 > 3;\n        bool _2261;\n        if (_2254)\n        {\n            _2261 = _2207 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2261 = _2254;\n        }\n        if (_2261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4303 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4303 = -_4303;\n    }\n    vec3 _3990 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n    Surface _3998 = fa_standard_surface(param_1);\n    vec3 _4334 = _3998.albedo;\n    float _4335 = _3998.alpha;\n    vec3 _4336 = _3998.normal;\n    float _4337 = _3998.metallic;\n    float _4338 = _3998.roughness;\n    float _4339 = _3998.occlusion;\n    vec3 _4340 = _3998.emission;\n    float _4341 = _3998.clearcoat;\n    float _4342 = _3998.clearcoat_roughness;\n    vec3 _4343 = _3998.sheen_color;\n    float _4344 = _3998.sheen_roughness;\n    float _4345 = _3998.anisotropy;\n    float _4346 = _3998.anisotropy_rotation;\n    float _4347 = _3998.specular;\n    float _4348 = _3998.ior;\n    vec3 _4349 = _3998.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n    Surface param_3 = _3998;\n    surface(param_2, param_3);\n    _4334 = param_3.albedo;\n    _4335 = param_3.alpha;\n    _4336 = param_3.normal;\n    _4337 = param_3.metallic;\n    _4338 = param_3.roughness;\n    _4339 = param_3.occlusion;\n    _4340 = param_3.emission;\n    _4341 = param_3.clearcoat;\n    _4342 = param_3.clearcoat_roughness;\n    _4343 = param_3.sheen_color;\n    _4344 = param_3.sheen_roughness;\n    _4345 = param_3.anisotropy;\n    _4346 = param_3.anisotropy_rotation;\n    _4347 = param_3.specular;\n    _4348 = param_3.ior;\n    _4349 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4303;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4334 = param_6;\n    _4336 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4334;\n    }\n    else\n    {\n        vec3 _4036 = _4336;\n        vec3 _4037 = normalize(_4036);\n        _4336 = _4037;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4303, fa_world_tangent, fa_uv, fa_vertex_color, _3990, gl_FrontFacing);\n        Surface param_9 = Surface(_4334, _4335, _4037, _4337, _4338, _4339, _4340, _4341, _4342, _4343, _4344, _4345, _4346, _4347, _4348, _4349);\n        result = lighting(param_8, param_9);\n    }\n    vec3 _4052 = result;\n    vec3 _4053 = _4052 + _4340;\n    result = _4053;\n    vec3 param_10 = _4053;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4062 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4069;\n    if (!_4062)\n    {\n        _4069 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4069 = _4062;\n    }\n    if (_4069)\n    {\n        vec3 _4078 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4084 = dot(_4078, fa_mesh_fs_params[9].xyz);\n        bool _4088 = fa_mesh_fs_params[9].w > 0.5;\n        float _4089;\n        if (_4088)\n        {\n            _4089 = _4084;\n        }\n        else\n        {\n            _4089 = length(_4078);\n        }\n        float _4101 = _4089 - fa_mesh_fs_params[8].x;\n        if (_4101 > 0.0)\n        {\n            float _4110 = fa_mesh_fs_params[7].w * _4101;\n            float tau = _4110 * _4110;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4126;\n                if (_4088)\n                {\n                    _4126 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4084);\n                }\n                else\n                {\n                    _4126 = fa_mesh_fs_params[0].y;\n                }\n                float _4147 = mix(_4126, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4089, 0.0, 1.0));\n                float _4151 = fa_world_pos.y - _4147;\n                float _4156 = _4147 - fa_mesh_fs_params[8].z;\n                float _4161 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4164 = _4156 <= 0.0;\n                bool _4165 = !_4164;\n                bool _4171;\n                if (_4165)\n                {\n                    _4171 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4171 = _4164;\n                }\n                float _4172;\n                if (_4171)\n                {\n                    _4172 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4172 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4156, 80.0));\n                }\n                bool _4199;\n                if (_4165)\n                {\n                    _4199 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4199 = _4164;\n                }\n                float _4200;\n                if (_4199)\n                {\n                    _4200 = fa_mesh_fs_params[8].y * _4156;\n                }\n                else\n                {\n                    _4200 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4156, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4225 = _4161 <= 0.0;\n                bool _4232;\n                if (!_4225)\n                {\n                    _4232 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4232 = _4225;\n                }\n                float _4233;\n                if (_4232)\n                {\n                    _4233 = fa_mesh_fs_params[8].y * _4161;\n                }\n                else\n                {\n                    _4233 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4161, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4260;\n                if (abs(_4151) < 0.001000000047497451305389404296875)\n                {\n                    _4260 = _4172;\n                }\n                else\n                {\n                    _4260 = (_4233 - _4200) / _4151;\n                }\n                tau += (_4101 * max(_4260, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4335);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_500",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_1240",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_3616",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
