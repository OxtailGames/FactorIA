{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "glsl430",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2747[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _560 = fa_mesh_fs_params[19].x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return vec4(0.0);\n    }\n    vec4 _599 = vec4(world_pos, 1.0);\n    float _606 = dot(fa_mesh_fs_params[16], _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _628 = vec2(dot(fa_mesh_fs_params[14], _599), dot(fa_mesh_fs_params[15], _599)) / vec2(_606);\n    int _632 = int(fa_mesh_fs_params[18].x);\n    int _636 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _632 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _712 = fa_cluster_texel(param);\n    return ivec2(int(_712.x), int(_712.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3811 = fa_cluster_lookup(param);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4000 = fa_linear_to_srgb(param);\n        c = _4000;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4008 = fa_srgb_to_linear(param_1);\n            c = _4008;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _311;\n    if (i.front_facing)\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    vec3 _335 = normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    vec3 _362 = normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    vec3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4039 = fa_tex_fix(param_2, param_3);\n    vec4 _5354 = base_t;\n    _5354.x = _4039.x;\n    _5354.y = _4039.y;\n    _5354.z = _4039.z;\n    base_t = _5354;\n    vec4 _4053 = (_5354 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5208 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4085 = fa_tex_fix(param_6, param_7);\n        vec3 _4088 = (_4085 * 2.0) - vec3(1.0);\n        vec2 _4093 = _4088.xy * fa_mesh_fs_params[6].x;\n        vec3 _5362 = _4088;\n        _5362.x = _4093.x;\n        _5362.y = _4093.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5362;\n        _5208 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4122 = fa_tex_fix(param_12, param_13);\n    vec4 _5365 = mrt;\n    _5365.x = _4122.x;\n    _5365.y = _4122.y;\n    _5365.z = _4122.z;\n    mrt = _5365;\n    vec4 _4150 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4150.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4162 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4192 = fa_tex_fix(param_20, param_21);\n    float _5213 = fa_mesh_fs_params[20].x;\n    float _5214 = fa_mesh_fs_params[20].y;\n    float _5217 = fa_mesh_fs_params[20].z;\n    float _5216 = fa_mesh_fs_params[21].w;\n    float _5219 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5213 *= _4162.y;\n            _5214 *= _4162.z;\n            _5216 *= _4150.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5217 *= mrt.x;\n            _5219 *= mrt.w;\n        }\n    }\n    return Surface(_4053.xyz, _4053.w, _5208, clamp(fa_mesh_fs_params[5].x * _4122.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4122.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4162.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4192), _5213, _5214, fa_mesh_fs_params[21].xyz, _5216, _5217, fa_mesh_fs_params[20].w, _5219, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _793 = rect.zw - rect.xy;\n    vec2 _797 = _793 * atlas;\n    vec2 _801 = ddx * _797;\n    vec2 _805 = ddy * _797;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _793), clamp(0.5 * log2(max(max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _840 = fa_mesh_fs_params[10].y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    vec3 _853 = dFdx(world_pos);\n    vec3 _856 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _860 = fa_cluster_texel(param);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _874;\n    vec4 _878 = fa_light_texel(param_1);\n    vec2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    vec4 _890 = fa_light_texel(param_2);\n    float _891 = _890.x;\n    int _897 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _901 = int(_860.z);\n    vec3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        vec4 _937 = fa_light_texel(param_4);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        vec4 _952 = fa_light_texel(param_5);\n        int param_6 = _932 + 1;\n        vec4 _957 = fa_light_texel(param_6);\n        int param_7 = _932 + 2;\n        vec4 _962 = fa_light_texel(param_7);\n        vec3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        vec3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        vec3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = clamp(dot(geo_normal, normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        vec2 _1048 = vec2(_970 + 0.5, 0.5 - _977);\n        vec2 _1058 = vec2(dot(_965, _853), dot(_972, _853));\n        vec2 _1068 = vec2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        vec4 _1073 = fa_light_texel(param_8);\n        int param_9 = _932 + 3;\n        vec4 _1078 = fa_light_texel(param_9);\n        int param_10 = _932 + 4;\n        vec4 _1083 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            vec4 param_11 = _1078;\n            vec2 param_12 = _1048;\n            vec2 param_13 = _881;\n            vec2 param_14 = _1058;\n            vec2 param_15 = _1068;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1119 = fa_dc_to_linear(param_16);\n                vec4 _5264 = tx;\n                _5264.x = _1119.x;\n                _5264.y = _1119.y;\n                _5264.z = _1119.z;\n                tx = _5264;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            vec4 param_17 = _1083;\n            vec2 param_18 = _1048;\n            vec2 param_19 = _881;\n            vec2 param_20 = _1058;\n            vec2 param_21 = _1068;\n            vec4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_891 > 1.5)\n            {\n                vec3 param_22 = _1163.xyz;\n                vec3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            vec3 _1183 = (_1167 * 2.0) - vec3(1.0);\n            vec2 _1188 = _1183.xy * _937.y;\n            vec3 _1210 = (normalize(_965) * _1188.x) + (normalize(_972) * _1188.y);\n            vec3 _1213 = normalize(normal);\n            normal = normalize(mix(_1213, normalize((_1213 * max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), vec3(clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2673 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5131 = false;\n    float _5132 = 1.0;\n    float _5133 = 1.0;\n    float _5134 = 1.0;\n    float _5135 = 0.0;\n    float _5136 = 0.0;\n    float _5137 = 0.0;\n    float _5138 = 0.0;\n    float _5140 = 1.0;\n    bool _5141 = false;\n    vec3 _5142 = vec3(0.0);\n    float _5143 = 1.0;\n    float _5144 = 1.0;\n    float _5145 = 1.0;\n    float _5146 = 0.0;\n    float _5147 = 0.0;\n    vec3 _5148 = vec3(1.0, 0.0, 0.0);\n    vec3 _5149 = vec3(0.0, 0.0, 1.0);\n    float _5150 = 1.0;\n    float _5151 = 1.0;\n    float _2824 = clamp(s.specular, 0.0, 1.0);\n    float _2828 = clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(min(vec3(_2851 * _2851) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2824, s.albedo, vec3(metallic));\n        _5132 = mix(_2824, 1.0, metallic);\n        _5131 = true;\n    }\n    float _2879 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5135 = _2879;\n        _5136 = _2887;\n        float _2894 = _2887 * _2887;\n        _5137 = _2894;\n        _5138 = _2894 * _2894;\n        float _2906 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5140 = _2906;\n        _5133 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5131 = true;\n    }\n    vec3 _2925 = max(s.sheen_color, vec3(0.0));\n    float _2934 = max(_2925.x, max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5141 = true;\n        _5142 = _2925;\n        _5143 = _2942;\n        _5144 = _2942 * _2942;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5146 = _2959;\n        _5145 = 1.0 - min(_2934 * _2959, 1.0);\n        _5131 = true;\n    }\n    _5134 = _5133 * _5145;\n    float _2978 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        vec3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3006 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3006.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3006.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3006.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3010 = t;\n        vec3 _3011 = normalize(_3010);\n        t = _3011;\n        vec3 _3036 = normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5148 = _3036;\n        _5149 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5150 = _3054 ? _3052 : _3046;\n        _5151 = _3054 ? _3046 : _3052;\n        _5147 = _2978;\n        _5131 = true;\n    }\n    return FaLayers(_5131, _5132, _5133, _5134, _5135, _5136, _5137, _5138, i.world_normal, _5140, _5141, _5142, _5143, _5144, _5145, _5146, _5147, _5148, _5149, _5150, _5151);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2430 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2430;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _429 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _435 = fa_light_texel(param_1);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    vec3 l;\n    if (_444)\n    {\n        l = normalize(_429.xyz);\n    }\n    else\n    {\n        vec3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / vec3(max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _493 = fa_light_texel(param_2);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _509 = fa_light_texel(param_3);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _435.xyz * atten, atten, 1.0, dist, _541);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1309 = fa_shadows[24].w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1392 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            vec2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            vec2 param_6 = uv + (_1425 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        vec2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1500 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1481);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1542 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1547 = clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = min(_1553 / max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1565 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1565 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1590 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < fa_shadows[ci * 1 + 16].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1643 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1643 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1590.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1560, 3.0)) * 0.5) / _1542;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(fa_shadows[25].x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2177 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2196 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = clamp((_2085 - (fa_shadow_split_at(param_7) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1701 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1722 = fa_light_texel(param);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    vec4 _1736 = fa_light_texel(param_1);\n    int param_2 = _1732 + 1;\n    vec4 _1741 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - fa_shadows[27].xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1780 = world - fa_light_texel(param_3).xyz;\n        vec3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    vec4 _1843 = fa_light_texel(param_6);\n    int param_7 = _1829 + 4;\n    vec4 _1848 = fa_light_texel(param_7);\n    int param_8 = _1829 + 5;\n    vec4 _1853 = fa_light_texel(param_8);\n    float _1865 = _1853.x * max(dot(_1843, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = min(sqrt(1.0 - (_1893 * _1893)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1843, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    vec4 _1941 = vec4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    vec2 _1963 = vec2(dot(fa_light_texel(param_4), _1941), dot(fa_light_texel(param_5), _1941)) / vec2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    vec2 param_10 = _1963;\n    vec4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * min(_1916, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3553 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3573 = fa_light_texel(param);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    vec3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        vec3 _3646 = _3621 + (l * (_3638 * len));\n        vec4 _3652 = vec4(_3646, 1.0);\n        float _3658 = dot(fa_mesh_fs_params[28], _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3678 = vec2(dot(fa_mesh_fs_params[26], _3652), dot(fa_mesh_fs_params[27], _3652)) / vec2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        vec4 _3743 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3683, _3687) * fa_mesh_fs_params[24].zw), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(fa_mesh_fs_params[29].xyz, _3646) + fa_mesh_fs_params[29].w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3683, 0.5 - _3682), min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3);\n    vec3 _5193 = _3866.direction;\n    vec3 _5188 = _3866.color;\n    float _5195 = _3866.attenuation;\n    float _5190 = _3866.shadow;\n    float _5197 = _3866._distance;\n    int _5198 = _3866.type;\n    bool _3869 = _5198 == 0;\n    if (_3869 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _5193;\n        float _3880 = fa_shadow_factor(param_4, param_5);\n        _5190 = _3880;\n        _5188 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5198 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5195 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _5193;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5190 = _3909;\n            _5188 *= _3909;\n        }\n    }\n    bool _3919 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5195 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5197;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _5193;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5190 *= _3950;\n        _5188 *= _3950;\n    }\n    return LightSample(_5193, _5188, _5195, _5190, _5197, _5198);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = max(dot(L.nc, l), 0.0);\n        float _3491 = max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2605 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2459 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3087, v), _3087), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3120 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3120.x) + (vec3(L.f90) * _3120.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3175 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2647 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2647.x) + vec3(_2647.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(fa_shadows[25].x + 0.5);\n    float _2262 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4910 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4910 = -_4910;\n    }\n    vec3 _4332 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n    Surface _4340 = fa_standard_surface(param_1);\n    vec3 _4941 = _4340.albedo;\n    float _4942 = _4340.alpha;\n    vec3 _4943 = _4340.normal;\n    float _4944 = _4340.metallic;\n    float _4945 = _4340.roughness;\n    float _4946 = _4340.occlusion;\n    vec3 _4947 = _4340.emission;\n    float _4948 = _4340.clearcoat;\n    float _4949 = _4340.clearcoat_roughness;\n    vec3 _4950 = _4340.sheen_color;\n    float _4951 = _4340.sheen_roughness;\n    float _4952 = _4340.anisotropy;\n    float _4953 = _4340.anisotropy_rotation;\n    float _4954 = _4340.specular;\n    float _4955 = _4340.ior;\n    vec3 _4956 = _4340.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n    Surface param_3 = _4340;\n    surface(param_2, param_3);\n    _4941 = param_3.albedo;\n    _4942 = param_3.alpha;\n    _4943 = param_3.normal;\n    _4944 = param_3.metallic;\n    _4945 = param_3.roughness;\n    _4946 = param_3.occlusion;\n    _4947 = param_3.emission;\n    _4948 = param_3.clearcoat;\n    _4949 = param_3.clearcoat_roughness;\n    _4950 = param_3.sheen_color;\n    _4951 = param_3.sheen_roughness;\n    _4952 = param_3.anisotropy;\n    _4953 = param_3.anisotropy_rotation;\n    _4954 = param_3.specular;\n    _4955 = param_3.ior;\n    _4956 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4910;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4941 = param_6;\n    _4943 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4941;\n    }\n    else\n    {\n        vec3 _4379 = normalize(_4943);\n        float _4386 = clamp(_4944, 0.0, 1.0);\n        float _4390 = clamp(_4945, 0.0500000007450580596923828125, 1.0);\n        float _4394 = _4390 * _4390;\n        float _4398 = _4394 * _4394;\n        float _4403 = max(dot(_4379, _4332), 9.9999997473787516355514526367188e-05);\n        vec3 _4409 = _4941 * (1.0 - _4386);\n        vec3 _4416 = mix(vec3(0.039999999105930328369140625), _4941, vec3(_4386));\n        vec3 f0 = _4416;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n        Surface param_9 = Surface(_4941, _4942, _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956);\n        vec3 param_10 = _4379;\n        vec3 param_11 = _4332;\n        float param_12 = _4386;\n        float param_13 = _4390;\n        vec3 param_14 = _4416;\n        FaLayers _4432 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4379;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4409) * _4946;\n        if (_4432.on)\n        {\n            lit *= _4432.base_scale;\n        }\n        int _4454 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4454; ln++)\n        {\n            int param_16 = ln;\n            int _4467 = fa_cl_light(param_16);\n            bool _4470 = fa_lm.z > 0.5;\n            bool _4476;\n            if (_4470)\n            {\n                int param_17 = _4467;\n                _4476 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4476 = _4470;\n            }\n            if (_4476)\n            {\n                continue;\n            }\n            int param_18 = _4467;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4910;\n            LightSample _4488 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _5115 = _4488.direction;\n            float _4496 = max(dot(_4379, _5115), 0.0);\n            float _4502 = _4488.attenuation * _4488.shadow;\n            vec3 _4507 = normalize(_5115 + _4332);\n            float _4512 = max(dot(_4379, _4507), 0.0);\n            float _4517 = max(dot(_4332, _4507), 0.0);\n            if (_4432.on)\n            {\n                FaLayers param_21 = _4432;\n                vec3 param_22 = _4409;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4379;\n                vec3 param_25 = _4332;\n                vec3 param_26 = _5115;\n                vec3 param_27 = _4507;\n                float param_28 = _4496;\n                float param_29 = _4403;\n                float param_30 = _4512;\n                float param_31 = _4517;\n                float param_32 = _4394;\n                float param_33 = _4398;\n                int param_34 = _4467;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4502));\n            }\n            else\n            {\n                float _4565 = ((_4512 * _4512) * (_4398 - 1.0)) + 1.0;\n                int param_35 = _4467;\n                lit += (((_4409 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4517, 5.0))) * (((_4398 / ((3.1415927410125732421875 * _4565) * _4565)) * (0.5 / max(mix((2.0 * _4496) * _4403, _4496 + _4403, _4394), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4496))) * fa_light_rgb(param_35)) * (_4496 * _4502));\n            }\n        }\n        if (_4432.on)\n        {\n            FaLayers param_36 = _4432;\n            vec3 param_37 = _4379;\n            vec3 param_38 = _4332;\n            vec3 param_39 = f0;\n            float param_40 = _4390;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4946);\n        }\n        else\n        {\n            vec3 param_41 = _4379;\n            vec3 param_42 = _4332;\n            vec3 param_43 = f0;\n            float param_44 = _4390;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4946);\n        }\n        result = lit;\n    }\n    vec3 _4658 = result;\n    vec3 _4659 = _4658 + _4947;\n    result = _4659;\n    vec3 param_45 = _4659;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4668 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4675;\n    if (!_4668)\n    {\n        _4675 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4675 = _4668;\n    }\n    if (_4675)\n    {\n        vec3 _4684 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4690 = dot(_4684, fa_mesh_fs_params[9].xyz);\n        bool _4694 = fa_mesh_fs_params[9].w > 0.5;\n        float _4695;\n        if (_4694)\n        {\n            _4695 = _4690;\n        }\n        else\n        {\n            _4695 = length(_4684);\n        }\n        float _4707 = _4695 - fa_mesh_fs_params[8].x;\n        if (_4707 > 0.0)\n        {\n            float _4716 = fa_mesh_fs_params[7].w * _4707;\n            float tau = _4716 * _4716;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4732;\n                if (_4694)\n                {\n                    _4732 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4690);\n                }\n                else\n                {\n                    _4732 = fa_mesh_fs_params[0].y;\n                }\n                float _4753 = mix(_4732, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4695, 0.0, 1.0));\n                float _4757 = fa_world_pos.y - _4753;\n                float _4762 = _4753 - fa_mesh_fs_params[8].z;\n                float _4767 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4770 = _4762 <= 0.0;\n                bool _4771 = !_4770;\n                bool _4777;\n                if (_4771)\n                {\n                    _4777 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4777 = _4770;\n                }\n                float _4778;\n                if (_4777)\n                {\n                    _4778 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4778 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4762, 80.0));\n                }\n                bool _4805;\n                if (_4771)\n                {\n                    _4805 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4805 = _4770;\n                }\n                float _4806;\n                if (_4805)\n                {\n                    _4806 = fa_mesh_fs_params[8].y * _4762;\n                }\n                else\n                {\n                    _4806 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4762, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4831 = _4767 <= 0.0;\n                bool _4838;\n                if (!_4831)\n                {\n                    _4838 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4838 = _4831;\n                }\n                float _4839;\n                if (_4838)\n                {\n                    _4839 = fa_mesh_fs_params[8].y * _4767;\n                }\n                else\n                {\n                    _4839 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4767, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4866;\n                if (abs(_4757) < 0.001000000047497451305389404296875)\n                {\n                    _4866 = _4778;\n                }\n                else\n                {\n                    _4866 = (_4839 - _4806) / _4757;\n                }\n                tau += (_4707 * max(_4866, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4942);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
            "inst_name": "_555",
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
            "inst_name": "_1295",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_188 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_188 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_188 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2747[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _560 = fa_mesh_fs_params[19].x < 0.0;\n    bool _567;\n    if (!_560)\n    {\n        _567 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _567 = _560;\n    }\n    bool _575;\n    if (!_567)\n    {\n        _575 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _575 = _567;\n    }\n    bool _582;\n    if (!_575)\n    {\n        _582 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _582 = _575;\n    }\n    bool _589;\n    if (!_582)\n    {\n        _589 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _589 = _582;\n    }\n    if (_589)\n    {\n        return vec4(0.0);\n    }\n    vec4 _599 = vec4(world_pos, 1.0);\n    float _606 = dot(fa_mesh_fs_params[16], _599);\n    if (!(_606 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _628 = vec2(dot(fa_mesh_fs_params[14], _599), dot(fa_mesh_fs_params[15], _599)) / vec2(_606);\n    int _632 = int(fa_mesh_fs_params[18].x);\n    int _636 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _636) + clamp(int(floor(((_628.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _636 - 1)) * _632)) + clamp(int(floor(((_628.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _632 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _712 = fa_cluster_texel(param);\n    return ivec2(int(_712.x), int(_712.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3811 = fa_cluster_lookup(param);\n    fa_cl_slot = _3811.x;\n    fa_cl_local = _3811.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4000 = fa_linear_to_srgb(param);\n        c = _4000;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4008 = fa_srgb_to_linear(param_1);\n            c = _4008;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _311;\n    if (i.front_facing)\n    {\n        _311 = i.world_normal;\n    }\n    else\n    {\n        _311 = -i.world_normal;\n    }\n    vec3 _335 = normalize(i.world_tangent.xyz - (_311 * dot(_311, i.world_tangent.xyz)));\n    vec3 _362 = normalize(((_335 * m.x) + ((cross(_311, _335) * i.world_tangent.w) * m.y)) + (_311 * m.z));\n    vec3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4039 = fa_tex_fix(param_2, param_3);\n    vec4 _5354 = base_t;\n    _5354.x = _4039.x;\n    _5354.y = _4039.y;\n    _5354.z = _4039.z;\n    base_t = _5354;\n    vec4 _4053 = (_5354 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5208 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4085 = fa_tex_fix(param_6, param_7);\n        vec3 _4088 = (_4085 * 2.0) - vec3(1.0);\n        vec2 _4093 = _4088.xy * fa_mesh_fs_params[6].x;\n        vec3 _5362 = _4088;\n        _5362.x = _4093.x;\n        _5362.y = _4093.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5362;\n        _5208 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4122 = fa_tex_fix(param_12, param_13);\n    vec4 _5365 = mrt;\n    _5365.x = _4122.x;\n    _5365.y = _4122.y;\n    _5365.z = _4122.z;\n    mrt = _5365;\n    vec4 _4150 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4150.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4162 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4192 = fa_tex_fix(param_20, param_21);\n    float _5213 = fa_mesh_fs_params[20].x;\n    float _5214 = fa_mesh_fs_params[20].y;\n    float _5217 = fa_mesh_fs_params[20].z;\n    float _5216 = fa_mesh_fs_params[21].w;\n    float _5219 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5213 *= _4162.y;\n            _5214 *= _4162.z;\n            _5216 *= _4150.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5217 *= mrt.x;\n            _5219 *= mrt.w;\n        }\n    }\n    return Surface(_4053.xyz, _4053.w, _5208, clamp(fa_mesh_fs_params[5].x * _4122.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4122.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4162.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4192), _5213, _5214, fa_mesh_fs_params[21].xyz, _5216, _5217, fa_mesh_fs_params[20].w, _5219, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _793 = rect.zw - rect.xy;\n    vec2 _797 = _793 * atlas;\n    vec2 _801 = ddx * _797;\n    vec2 _805 = ddy * _797;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _793), clamp(0.5 * log2(max(max(dot(_801, _801), dot(_805, _805)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _840 = fa_mesh_fs_params[10].y < 0.5;\n    bool _847;\n    if (!_840)\n    {\n        _847 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _847 = _840;\n    }\n    if (_847)\n    {\n        return;\n    }\n    vec3 _853 = dFdx(world_pos);\n    vec3 _856 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _860 = fa_cluster_texel(param);\n    int _864 = int(_860.w);\n    if (_864 < 1)\n    {\n        return;\n    }\n    int _874 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _874;\n    vec4 _878 = fa_light_texel(param_1);\n    vec2 _881 = _878.yz;\n    int _885 = int(_878.w);\n    int param_2 = _874 + 1;\n    vec4 _890 = fa_light_texel(param_2);\n    float _891 = _890.x;\n    int _897 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _901 = int(_860.z);\n    vec3 _1167;\n    for (int k = 0; k < _864; k++)\n    {\n        int _914 = _901 + k;\n        int param_3 = _885 + (_914 >> 2);\n        int _932 = (_874 + 2) + (int(fa_light_texel(param_3)[_914 & 3]) * 7);\n        int param_4 = _932 + 6;\n        vec4 _937 = fa_light_texel(param_4);\n        if (((int(_937.w + 0.5) >> _897) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _932;\n        vec4 _952 = fa_light_texel(param_5);\n        int param_6 = _932 + 1;\n        vec4 _957 = fa_light_texel(param_6);\n        int param_7 = _932 + 2;\n        vec4 _962 = fa_light_texel(param_7);\n        vec3 _965 = _952.xyz;\n        float _970 = dot(_965, world_pos) + _952.w;\n        vec3 _972 = _957.xyz;\n        float _977 = dot(_972, world_pos) + _957.w;\n        vec3 _979 = _962.xyz;\n        float _984 = dot(_979, world_pos) + _962.w;\n        bool _989 = abs(_970) > 0.5;\n        bool _997;\n        if (!_989)\n        {\n            _997 = abs(_977) > 0.5;\n        }\n        else\n        {\n            _997 = _989;\n        }\n        bool _1005;\n        if (!_997)\n        {\n            _1005 = abs(_984) > 0.5;\n        }\n        else\n        {\n            _1005 = _997;\n        }\n        if (_1005)\n        {\n            continue;\n        }\n        float _1020 = clamp(dot(geo_normal, normalize(_979)) * _937.z, 0.0, 1.0);\n        if (_1020 <= 0.0)\n        {\n            continue;\n        }\n        float _1040 = (clamp((0.5 - abs(_984)) * 10.0, 0.0, 1.0) * _1020) * _937.x;\n        vec2 _1048 = vec2(_970 + 0.5, 0.5 - _977);\n        vec2 _1058 = vec2(dot(_965, _853), dot(_972, _853));\n        vec2 _1068 = vec2(dot(_965, _856), dot(_972, _856));\n        int param_8 = _932 + 5;\n        vec4 _1073 = fa_light_texel(param_8);\n        int param_9 = _932 + 3;\n        vec4 _1078 = fa_light_texel(param_9);\n        int param_10 = _932 + 4;\n        vec4 _1083 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1073.xyz;\n        bool _1093 = _1078.z > _1078.x;\n        if (_1093)\n        {\n            vec4 param_11 = _1078;\n            vec2 param_12 = _1048;\n            vec2 param_13 = _881;\n            vec2 param_14 = _1058;\n            vec2 param_15 = _1068;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_891 > 0.5) && (_891 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1119 = fa_dc_to_linear(param_16);\n                vec4 _5264 = tx;\n                _5264.x = _1119.x;\n                _5264.y = _1119.y;\n                _5264.z = _1119.z;\n                tx = _5264;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1040 * tex_a) * _1073.w, 0.0, 1.0)));\n        if (_1083.z > _1083.x)\n        {\n            vec4 param_17 = _1083;\n            vec2 param_18 = _1048;\n            vec2 param_19 = _881;\n            vec2 param_20 = _1058;\n            vec2 param_21 = _1068;\n            vec4 _1163 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_891 > 1.5)\n            {\n                vec3 param_22 = _1163.xyz;\n                vec3 _1173 = fa_dc_to_srgb(param_22);\n                _1167 = _1173;\n            }\n            else\n            {\n                _1167 = _1163.xyz;\n            }\n            vec3 _1183 = (_1167 * 2.0) - vec3(1.0);\n            vec2 _1188 = _1183.xy * _937.y;\n            vec3 _1210 = (normalize(_965) * _1188.x) + (normalize(_972) * _1188.y);\n            vec3 _1213 = normalize(normal);\n            normal = normalize(mix(_1213, normalize((_1213 * max(_1183.z, 0.0500000007450580596923828125)) + (_1210 - (_1213 * dot(_1213, _1210)))), vec3(clamp(_1040 * (_1093 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2673 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2680 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2683 = int(_2673);\n    int _2686 = int(_2680);\n    float _2696 = _2680 - float(_2686);\n    int _2751 = (_2683 * 9) + _2686;\n    int _2771 = ((_2683 + 1) * 9) + _2686;\n    return mix(mix(_2747[_2751], _2747[_2751 + 1], _2696), mix(_2747[_2771], _2747[_2771 + 1], _2696), _2673 - float(_2683));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5131 = false;\n    float _5132 = 1.0;\n    float _5133 = 1.0;\n    float _5134 = 1.0;\n    float _5135 = 0.0;\n    float _5136 = 0.0;\n    float _5137 = 0.0;\n    float _5138 = 0.0;\n    float _5140 = 1.0;\n    bool _5141 = false;\n    vec3 _5142 = vec3(0.0);\n    float _5143 = 1.0;\n    float _5144 = 1.0;\n    float _5145 = 1.0;\n    float _5146 = 0.0;\n    float _5147 = 0.0;\n    vec3 _5148 = vec3(1.0, 0.0, 0.0);\n    vec3 _5149 = vec3(0.0, 0.0, 1.0);\n    float _5150 = 1.0;\n    float _5151 = 1.0;\n    float _2824 = clamp(s.specular, 0.0, 1.0);\n    float _2828 = clamp(s.ior, 1.0, 3.0);\n    bool _2833 = (_2824 != 1.0) || (_2828 != 1.5);\n    bool _2843;\n    if (!_2833)\n    {\n        _2843 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2843 = _2833;\n    }\n    if (_2843)\n    {\n        float _2851 = (_2828 - 1.0) / (_2828 + 1.0);\n        f0 = mix(min(vec3(_2851 * _2851) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2824, s.albedo, vec3(metallic));\n        _5132 = mix(_2824, 1.0, metallic);\n        _5131 = true;\n    }\n    float _2879 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2879 > 0.0)\n    {\n        float _2887 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5135 = _2879;\n        _5136 = _2887;\n        float _2894 = _2887 * _2887;\n        _5137 = _2894;\n        _5138 = _2894 * _2894;\n        float _2906 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5140 = _2906;\n        _5133 = 1.0 - (_2879 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2906, 0.0, 1.0), 5.0))));\n        _5131 = true;\n    }\n    vec3 _2925 = max(s.sheen_color, vec3(0.0));\n    float _2934 = max(_2925.x, max(_2925.y, _2925.z));\n    if (_2934 > 0.0)\n    {\n        float _2942 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5141 = true;\n        _5142 = _2925;\n        _5143 = _2942;\n        _5144 = _2942 * _2942;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2942;\n        float _2959 = fa_sheen_albedo(param, param_1);\n        _5146 = _2959;\n        _5145 = 1.0 - min(_2934 * _2959, 1.0);\n        _5131 = true;\n    }\n    _5134 = _5133 * _5145;\n    float _2978 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2978 != 0.0)\n    {\n        vec3 _2993 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2993;\n        if (dot(_2993, _2993) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3006 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3006.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3006.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3006.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3010 = t;\n        vec3 _3011 = normalize(_3010);\n        t = _3011;\n        vec3 _3036 = normalize((_3011 * cos(s.anisotropy_rotation)) + ((cross(n, _3011) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5148 = _3036;\n        _5149 = cross(n, _3036);\n        float _3046 = roughness * roughness;\n        float _3052 = mix(_3046, 1.0, _2978 * _2978);\n        bool _3054 = _2978 > 0.0;\n        _5150 = _3054 ? _3052 : _3046;\n        _5151 = _3054 ? _3046 : _3052;\n        _5147 = _2978;\n        _5131 = true;\n    }\n    return FaLayers(_5131, _5132, _5133, _5134, _5135, _5136, _5137, _5138, i.world_normal, _5140, _5141, _5142, _5143, _5144, _5145, _5146, _5147, _5148, _5149, _5150, _5151);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2430 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2430;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _429 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _435 = fa_light_texel(param_1);\n    float _438 = _435.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _444 = _438 < 0.5;\n    vec3 l;\n    if (_444)\n    {\n        l = normalize(_429.xyz);\n    }\n    else\n    {\n        vec3 _456 = _429.xyz - world_pos;\n        float _458 = length(_456);\n        dist = _458;\n        l = _456 / vec3(max(_458, 9.9999997473787516355514526367188e-05));\n        float _473 = _458 / max(_429.w, 0.001000000047497451305389404296875);\n        float _479 = clamp(1.0 - (_473 * _473), 0.0, 1.0);\n        atten = _479 * _479;\n        if (_438 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _493 = fa_light_texel(param_2);\n            float _503 = _493.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _509 = fa_light_texel(param_3);\n            float _510 = _509.x;\n            float cos_inner = _510;\n            if (_510 > 1.5)\n            {\n                cos_inner = mix(_503, 1.0, 0.25);\n            }\n            atten *= smoothstep(_503, cos_inner, dot(-l, normalize(_493.xyz)));\n        }\n    }\n    int _541;\n    if (_444)\n    {\n        _541 = 0;\n    }\n    else\n    {\n        _541 = (_438 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _435.xyz * atten, atten, 1.0, dist, _541);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1285;\n    if (i == 0)\n    {\n        _1285 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1301;\n        if (i == 1)\n        {\n            _1301 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1309;\n            if (i == 2)\n            {\n                _1309 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1309 = fa_shadows[24].w;\n            }\n            _1301 = _1309;\n        }\n        _1285 = _1301;\n    }\n    return _1285;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1342 = fa_shadow_depth(param, param_1);\n    float _1346;\n    if (conv.x < 0.5)\n    {\n        _1346 = _1342;\n    }\n    else\n    {\n        _1346 = (conv.y * conv.z) / (conv.z - (_1342 * (conv.z - conv.y)));\n    }\n    return _1346;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1273 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1273), sin(_1273)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1392 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1406 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1392;\n            vec2 _1425 = fa_shadow_vogel(param_3, param_4, param_5) * _1406;\n            vec2 param_6 = uv + (_1425 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1437 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1437 < (zr - (length(_1425) * plane)))\n            {\n                sum += _1437;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1481 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1481; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1481;\n        float param_11 = _1392;\n        vec2 _1500 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1500 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1500) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1481);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1542 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1547 = clamp(dot(n, l), 0.0, 1.0);\n    float _1553 = sqrt(1.0 - (_1547 * _1547));\n    float _1560 = min(_1553 / max(_1547, 0.20000000298023223876953125), 4.0);\n    float _1565;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1565 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1565 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1590 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1565 * _1553)), 1.0);\n    float _1597 = _1590.x;\n    bool _1600 = _1597 < fa_shadows[ci * 1 + 16].x;\n    bool _1609;\n    if (!_1600)\n    {\n        _1609 = _1597 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1609 = _1600;\n    }\n    bool _1618;\n    if (!_1609)\n    {\n        _1618 = _1590.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1618 = _1609;\n    }\n    bool _1627;\n    if (!_1618)\n    {\n        _1627 = _1590.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1627 = _1618;\n    }\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _1590.z > 1.0;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return -1.0;\n    }\n    float _1643;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1643 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1643 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1590.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1590.z - ((_1643 * (1.0 + (0.5 * _1560))) / _1542);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1542;\n    float param_5 = _1542 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1560, 3.0)) * 0.5) / _1542;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2070 = int(fa_shadows[25].x + 0.5);\n    if (_2070 < 1)\n    {\n        return 1.0;\n    }\n    float _2085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2070 - 1;\n    if (_2085 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2097 = _2070 > 1;\n    bool _2104;\n    if (_2097)\n    {\n        _2104 = _2085 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2104 = _2097;\n    }\n    if (_2104)\n    {\n        ci = 1;\n    }\n    bool _2108 = _2070 > 2;\n    bool _2115;\n    if (_2108)\n    {\n        _2115 = _2085 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2115 = _2108;\n    }\n    if (_2115)\n    {\n        ci = 2;\n    }\n    bool _2119 = _2070 > 3;\n    bool _2126;\n    if (_2119)\n    {\n        _2126 = _2085 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2126 = _2119;\n    }\n    if (_2126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2070)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2152;\n        if (_2152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2177 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2196 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2207 = clamp((_2085 - (fa_shadow_split_at(param_7) - _2196)) / _2196, 0.0, 1.0);\n        if (_2207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2070)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2228;\n                if (_2228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1701 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1709;\n    if (!_1701)\n    {\n        _1709 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1709 = _1701;\n    }\n    if (_1709)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1722 = fa_light_texel(param);\n    float _1723 = _1722.x;\n    if (_1723 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1732 = int(_1723 + 0.5);\n    int param_1 = _1732;\n    vec4 _1736 = fa_light_texel(param_1);\n    int param_2 = _1732 + 1;\n    vec4 _1741 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1744 = _1736.y;\n    if (_1744 > 0.0)\n    {\n        float _1761 = 1.0 - smoothstep(0.75 * _1744, _1744, length(world - fa_shadows[27].xyz));\n        fade = _1761;\n        if (_1761 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1736.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1780 = world - fa_light_texel(param_3).xyz;\n        vec3 _1783 = abs(_1780);\n        float _1785 = _1783.x;\n        float _1787 = _1783.y;\n        bool _1788 = _1785 >= _1787;\n        bool _1796;\n        if (_1788)\n        {\n            _1796 = _1785 >= _1783.z;\n        }\n        else\n        {\n            _1796 = _1788;\n        }\n        int _1797;\n        if (_1796)\n        {\n            _1797 = (_1780.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1810;\n            if (_1787 >= _1783.z)\n            {\n                _1810 = (_1780.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1810 = (_1780.z > 0.0) ? 4 : 5;\n            }\n            _1797 = _1810;\n        }\n        face = _1797;\n    }\n    int _1829 = (_1732 + 2) + (face * 6);\n    int param_4 = _1829;\n    int param_5 = _1829 + 1;\n    int param_6 = _1829 + 3;\n    vec4 _1843 = fa_light_texel(param_6);\n    int param_7 = _1829 + 4;\n    vec4 _1848 = fa_light_texel(param_7);\n    int param_8 = _1829 + 5;\n    vec4 _1853 = fa_light_texel(param_8);\n    float _1865 = _1853.x * max(dot(_1843, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1870 = clamp(dot(n, l), 0.0, 1.0);\n    float _1893 = clamp(dot(n, _1843.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1916 = min(sqrt(1.0 - (_1893 * _1893)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1843, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1919 = _1741.y;\n    float _1921;\n    if (_1919 > 0.0)\n    {\n        _1921 = _1919;\n    }\n    else\n    {\n        _1921 = 1.5 * _1865;\n    }\n    vec4 _1941 = vec4(world + (n * (_1921 * sqrt(1.0 - (_1870 * _1870)))), 1.0);\n    float _1945 = dot(_1843, _1941);\n    float _1948 = _1853.y;\n    if (_1945 < _1948)\n    {\n        return 1.0;\n    }\n    vec2 _1963 = vec2(dot(fa_light_texel(param_4), _1941), dot(fa_light_texel(param_5), _1941)) / vec2(_1945);\n    float _1965 = _1963.x;\n    bool _1968 = _1965 < _1848.x;\n    bool _1977;\n    if (!_1968)\n    {\n        _1977 = _1965 > _1848.z;\n    }\n    else\n    {\n        _1977 = _1968;\n    }\n    bool _1986;\n    if (!_1977)\n    {\n        _1986 = _1963.y < _1848.y;\n    }\n    else\n    {\n        _1986 = _1977;\n    }\n    bool _1995;\n    if (!_1986)\n    {\n        _1995 = _1963.y > _1848.w;\n    }\n    else\n    {\n        _1995 = _1986;\n    }\n    if (_1995)\n    {\n        return 1.0;\n    }\n    float _2001 = _1741.x;\n    float _2003;\n    if (_2001 > 0.0)\n    {\n        _2003 = _2001;\n    }\n    else\n    {\n        _2003 = 1.5 * _1865;\n    }\n    vec2 param_10 = _1963;\n    vec4 param_11 = _1848;\n    float param_12 = _1945 - (_2003 * (1.0 + (0.5 * _1916)));\n    float param_13 = _1865;\n    float param_14 = 1.0;\n    float param_15 = _1853.z * 0.25;\n    float param_16 = (_1865 * min(_1916, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1948, _1853.z);\n    int param_18 = int(_1736.z + 0.5);\n    float param_19 = _1736.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3553 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3560;\n    if (!_3553)\n    {\n        _3560 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3560 = _3553;\n    }\n    if (_3560)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3573 = fa_light_texel(param);\n    float _3574 = _3573.y;\n    float len = _3574;\n    if (_3574 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3586 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3596 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3586);\n    if (_3596 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3602 = len;\n    float _3605 = min(_3602, 0.89999997615814208984375 * dist);\n    len = _3605;\n    float _3610 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3586);\n    float _3615 = _3610 + (0.5 * _3605);\n    vec3 _3621 = world + (gn * _3610);\n    float _3623 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3687;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3638 = (float(k) + _3623) * 0.083333335816860198974609375;\n        vec3 _3646 = _3621 + (l * (_3638 * len));\n        vec4 _3652 = vec4(_3646, 1.0);\n        float _3658 = dot(fa_mesh_fs_params[28], _3652);\n        if (_3658 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3678 = vec2(dot(fa_mesh_fs_params[26], _3652), dot(fa_mesh_fs_params[27], _3652)) / vec2(_3658);\n        float _3682 = _3678.x * 0.5;\n        float _3683 = _3682 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3687 = (_3678.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3687 = 0.5 - (_3678.y * 0.5);\n        }\n        bool _3703 = _3683 < 0.0;\n        bool _3710;\n        if (!_3703)\n        {\n            _3710 = _3683 >= 1.0;\n        }\n        else\n        {\n            _3710 = _3703;\n        }\n        bool _3717;\n        if (!_3710)\n        {\n            _3717 = _3687 < 0.0;\n        }\n        else\n        {\n            _3717 = _3710;\n        }\n        bool _3724;\n        if (!_3717)\n        {\n            _3724 = _3687 >= 1.0;\n        }\n        else\n        {\n            _3724 = _3717;\n        }\n        if (_3724)\n        {\n            break;\n        }\n        vec4 _3743 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3683, _3687) * fa_mesh_fs_params[24].zw), 0);\n        if (_3743.w < 0.5)\n        {\n            continue;\n        }\n        float _3762 = (dot(fa_mesh_fs_params[29].xyz, _3646) + fa_mesh_fs_params[29].w) - _3743.x;\n        if ((_3762 > _3610) && (_3762 < _3615))\n        {\n            occ = max(occ, (1.0 - (_3638 * _3638)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3683, 0.5 - _3682), min(_3687, 1.0 - _3687))));\n        }\n    }\n    return 1.0 - (occ * _3596);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3838 = fa_lm.z > 0.5;\n    bool _3844;\n    if (_3838)\n    {\n        int param = li;\n        _3844 = fa_light_baked(param);\n    }\n    else\n    {\n        _3844 = _3838;\n    }\n    if (_3844)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3866 = fa_light_sample(param_2, param_3);\n    vec3 _5193 = _3866.direction;\n    vec3 _5188 = _3866.color;\n    float _5195 = _3866.attenuation;\n    float _5190 = _3866.shadow;\n    float _5197 = _3866._distance;\n    int _5198 = _3866.type;\n    bool _3869 = _5198 == 0;\n    if (_3869 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _5193;\n        float _3880 = fa_shadow_factor(param_4, param_5);\n        _5190 = _3880;\n        _5188 *= _3880;\n    }\n    else\n    {\n        bool _3891 = _5198 != 0;\n        bool _3897;\n        if (_3891)\n        {\n            _3897 = _5195 > 0.0;\n        }\n        else\n        {\n            _3897 = _3891;\n        }\n        if (_3897)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _5193;\n            float _3909 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _5190 = _3909;\n            _5188 *= _3909;\n        }\n    }\n    bool _3919 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3925;\n    if (_3919)\n    {\n        _3925 = _5195 > 0.0;\n    }\n    else\n    {\n        _3925 = _3919;\n    }\n    if (_3925)\n    {\n        float _3932;\n        if (_3869)\n        {\n            _3932 = 1000000000.0;\n        }\n        else\n        {\n            _3932 = _5197;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _5193;\n        float param_14 = _3932;\n        float _3950 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _5190 *= _3950;\n        _5188 *= _3950;\n    }\n    return LightSample(_5193, _5188, _5195, _5190, _5197, _5198);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3204 = tdh / at;\n    float _3208 = bdh / ab;\n    float _3220 = ((_3204 * _3204) + (_3208 * _3208)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3220) * _3220);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3301 = 1.0 / alpha;\n    return ((2.0 + _3301) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3301)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3333 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3412 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3412) * _3412);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3333);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3333));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3485 = max(dot(L.nc, l), 0.0);\n        float _3491 = max(dot(L.nc, h), 0.0);\n        float _3500 = ((_3491 * _3491) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3500) * _3500)) * (0.5 / max(mix((2.0 * _3485) * L.coat_ndv, _3485 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3485)) * _3485);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2605 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2608 = _2605.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2608 * _2608, exp2((-9.27999973297119140625) * ndv)) * _2608) + _2605.y)) + _2605.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2459 = rough * rough;\n    float _2489 = 0.60000002384185791015625 * _2459;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2459)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2489, 0.0500000007450580596923828125 + _2489, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2459 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3087;\n        if (L.aniso >= 0.0)\n        {\n            _3087 = L.b;\n        }\n        else\n        {\n            _3087 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3087, v), _3087), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3120 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3120.x) + (vec3(L.f90) * _3120.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3175 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3175.x) + _3175.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2647 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2647.x) + vec3(_2647.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2252 = int(fa_shadows[25].x + 0.5);\n    float _2262 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2267 = _2252 > 0;\n    bool _2276;\n    if (_2267)\n    {\n        int param = _2252 - 1;\n        _2276 = _2262 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2276 = _2267;\n    }\n    if (_2276)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2283 = _2252 > 1;\n        bool _2290;\n        if (_2283)\n        {\n            _2290 = _2262 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2290 = _2283;\n        }\n        if (_2290)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2296 = _2252 > 2;\n        bool _2303;\n        if (_2296)\n        {\n            _2303 = _2262 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2303 = _2296;\n        }\n        if (_2303)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2309 = _2252 > 3;\n        bool _2316;\n        if (_2309)\n        {\n            _2316 = _2262 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2316 = _2309;\n        }\n        if (_2316)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4910 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4910 = -_4910;\n    }\n    vec3 _4332 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n    Surface _4340 = fa_standard_surface(param_1);\n    vec3 _4941 = _4340.albedo;\n    float _4942 = _4340.alpha;\n    vec3 _4943 = _4340.normal;\n    float _4944 = _4340.metallic;\n    float _4945 = _4340.roughness;\n    float _4946 = _4340.occlusion;\n    vec3 _4947 = _4340.emission;\n    float _4948 = _4340.clearcoat;\n    float _4949 = _4340.clearcoat_roughness;\n    vec3 _4950 = _4340.sheen_color;\n    float _4951 = _4340.sheen_roughness;\n    float _4952 = _4340.anisotropy;\n    float _4953 = _4340.anisotropy_rotation;\n    float _4954 = _4340.specular;\n    float _4955 = _4340.ior;\n    vec3 _4956 = _4340.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n    Surface param_3 = _4340;\n    surface(param_2, param_3);\n    _4941 = param_3.albedo;\n    _4942 = param_3.alpha;\n    _4943 = param_3.normal;\n    _4944 = param_3.metallic;\n    _4945 = param_3.roughness;\n    _4946 = param_3.occlusion;\n    _4947 = param_3.emission;\n    _4948 = param_3.clearcoat;\n    _4949 = param_3.clearcoat_roughness;\n    _4950 = param_3.sheen_color;\n    _4951 = param_3.sheen_roughness;\n    _4952 = param_3.anisotropy;\n    _4953 = param_3.anisotropy_rotation;\n    _4954 = param_3.specular;\n    _4955 = param_3.ior;\n    _4956 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4910;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4941 = param_6;\n    _4943 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4941;\n    }\n    else\n    {\n        vec3 _4379 = normalize(_4943);\n        float _4386 = clamp(_4944, 0.0, 1.0);\n        float _4390 = clamp(_4945, 0.0500000007450580596923828125, 1.0);\n        float _4394 = _4390 * _4390;\n        float _4398 = _4394 * _4394;\n        float _4403 = max(dot(_4379, _4332), 9.9999997473787516355514526367188e-05);\n        vec3 _4409 = _4941 * (1.0 - _4386);\n        vec3 _4416 = mix(vec3(0.039999999105930328369140625), _4941, vec3(_4386));\n        vec3 f0 = _4416;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4910, fa_world_tangent, fa_uv, fa_vertex_color, _4332, gl_FrontFacing);\n        Surface param_9 = Surface(_4941, _4942, _4943, _4944, _4945, _4946, _4947, _4948, _4949, _4950, _4951, _4952, _4953, _4954, _4955, _4956);\n        vec3 param_10 = _4379;\n        vec3 param_11 = _4332;\n        float param_12 = _4386;\n        float param_13 = _4390;\n        vec3 param_14 = _4416;\n        FaLayers _4432 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4379;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4409) * _4946;\n        if (_4432.on)\n        {\n            lit *= _4432.base_scale;\n        }\n        int _4454 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4454; ln++)\n        {\n            int param_16 = ln;\n            int _4467 = fa_cl_light(param_16);\n            bool _4470 = fa_lm.z > 0.5;\n            bool _4476;\n            if (_4470)\n            {\n                int param_17 = _4467;\n                _4476 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4476 = _4470;\n            }\n            if (_4476)\n            {\n                continue;\n            }\n            int param_18 = _4467;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4910;\n            LightSample _4488 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _5115 = _4488.direction;\n            float _4496 = max(dot(_4379, _5115), 0.0);\n            float _4502 = _4488.attenuation * _4488.shadow;\n            vec3 _4507 = normalize(_5115 + _4332);\n            float _4512 = max(dot(_4379, _4507), 0.0);\n            float _4517 = max(dot(_4332, _4507), 0.0);\n            if (_4432.on)\n            {\n                FaLayers param_21 = _4432;\n                vec3 param_22 = _4409;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4379;\n                vec3 param_25 = _4332;\n                vec3 param_26 = _5115;\n                vec3 param_27 = _4507;\n                float param_28 = _4496;\n                float param_29 = _4403;\n                float param_30 = _4512;\n                float param_31 = _4517;\n                float param_32 = _4394;\n                float param_33 = _4398;\n                int param_34 = _4467;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4502));\n            }\n            else\n            {\n                float _4565 = ((_4512 * _4512) * (_4398 - 1.0)) + 1.0;\n                int param_35 = _4467;\n                lit += (((_4409 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4517, 5.0))) * (((_4398 / ((3.1415927410125732421875 * _4565) * _4565)) * (0.5 / max(mix((2.0 * _4496) * _4403, _4496 + _4403, _4394), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4496))) * fa_light_rgb(param_35)) * (_4496 * _4502));\n            }\n        }\n        if (_4432.on)\n        {\n            FaLayers param_36 = _4432;\n            vec3 param_37 = _4379;\n            vec3 param_38 = _4332;\n            vec3 param_39 = f0;\n            float param_40 = _4390;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4946);\n        }\n        else\n        {\n            vec3 param_41 = _4379;\n            vec3 param_42 = _4332;\n            vec3 param_43 = f0;\n            float param_44 = _4390;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4946);\n        }\n        result = lit;\n    }\n    vec3 _4658 = result;\n    vec3 _4659 = _4658 + _4947;\n    result = _4659;\n    vec3 param_45 = _4659;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4668 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4675;\n    if (!_4668)\n    {\n        _4675 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4675 = _4668;\n    }\n    if (_4675)\n    {\n        vec3 _4684 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4690 = dot(_4684, fa_mesh_fs_params[9].xyz);\n        bool _4694 = fa_mesh_fs_params[9].w > 0.5;\n        float _4695;\n        if (_4694)\n        {\n            _4695 = _4690;\n        }\n        else\n        {\n            _4695 = length(_4684);\n        }\n        float _4707 = _4695 - fa_mesh_fs_params[8].x;\n        if (_4707 > 0.0)\n        {\n            float _4716 = fa_mesh_fs_params[7].w * _4707;\n            float tau = _4716 * _4716;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4732;\n                if (_4694)\n                {\n                    _4732 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4690);\n                }\n                else\n                {\n                    _4732 = fa_mesh_fs_params[0].y;\n                }\n                float _4753 = mix(_4732, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4695, 0.0, 1.0));\n                float _4757 = fa_world_pos.y - _4753;\n                float _4762 = _4753 - fa_mesh_fs_params[8].z;\n                float _4767 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4770 = _4762 <= 0.0;\n                bool _4771 = !_4770;\n                bool _4777;\n                if (_4771)\n                {\n                    _4777 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4777 = _4770;\n                }\n                float _4778;\n                if (_4777)\n                {\n                    _4778 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4778 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4762, 80.0));\n                }\n                bool _4805;\n                if (_4771)\n                {\n                    _4805 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4805 = _4770;\n                }\n                float _4806;\n                if (_4805)\n                {\n                    _4806 = fa_mesh_fs_params[8].y * _4762;\n                }\n                else\n                {\n                    _4806 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4762, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4831 = _4767 <= 0.0;\n                bool _4838;\n                if (!_4831)\n                {\n                    _4838 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4838 = _4831;\n                }\n                float _4839;\n                if (_4838)\n                {\n                    _4839 = fa_mesh_fs_params[8].y * _4767;\n                }\n                else\n                {\n                    _4839 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4767, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4866;\n                if (abs(_4757) < 0.001000000047497451305389404296875)\n                {\n                    _4866 = _4778;\n                }\n                else\n                {\n                    _4866 = (_4839 - _4806) / _4757;\n                }\n                tau += (_4707 * max(_4866, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4942);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
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
            "inst_name": "_197",
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
            "inst_name": "_555",
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
            "inst_name": "_1295",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _182 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _189 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_182 * _189).z;\n    fa_pre_r0 = vec3(_182[0].x, _182[1].x, _182[2].x);\n    fa_pre_r1 = vec3(_182[0].y, _182[1].y, _182[2].y);\n    fa_pre_r2 = vec3(_182[0].z, _182[1].z, _182[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _189;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _737 = base_t;\n    _737.x = _225.x;\n    _737.y = _225.y;\n    _737.z = _225.z;\n    base_t = _737;\n    vec4 _241 = (_737 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _700 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _745 = _279;\n        _745.x = _284.x;\n        _745.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _745;\n        _700 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _748 = mrt;\n    _748.x = _313.x;\n    _748.y = _313.y;\n    _748.z = _313.z;\n    mrt = _748;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _705 = fa_mesh_fs_params[20].x;\n    float _706 = fa_mesh_fs_params[20].y;\n    float _709 = fa_mesh_fs_params[20].z;\n    float _708 = fa_mesh_fs_params[21].w;\n    float _711 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _705 *= _355.y;\n            _706 *= _355.z;\n            _708 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _709 *= mrt.x;\n            _711 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _700, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _705, _706, fa_mesh_fs_params[21].xyz, _708, _709, fa_mesh_fs_params[20].w, _711, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _611 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _611 = -_611;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_45",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_145",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _188 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_188 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_188 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_188 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _295 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _302 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_295 * _302).z;\n    fa_pre_r0 = vec3(_295[0].x, _295[1].x, _295[2].x);\n    fa_pre_r1 = vec3(_295[0].y, _295[1].y, _295[2].y);\n    fa_pre_r2 = vec3(_295[0].z, _295[1].z, _295[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _302;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _737 = base_t;\n    _737.x = _225.x;\n    _737.y = _225.y;\n    _737.z = _225.z;\n    base_t = _737;\n    vec4 _241 = (_737 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _700 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _745 = _279;\n        _745.x = _284.x;\n        _745.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _745;\n        _700 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _748 = mrt;\n    _748.x = _313.x;\n    _748.y = _313.y;\n    _748.z = _313.z;\n    mrt = _748;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _705 = fa_mesh_fs_params[20].x;\n    float _706 = fa_mesh_fs_params[20].y;\n    float _709 = fa_mesh_fs_params[20].z;\n    float _708 = fa_mesh_fs_params[21].w;\n    float _711 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _705 *= _355.y;\n            _706 *= _355.z;\n            _708 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _709 *= mrt.x;\n            _711 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _700, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _705, _706, fa_mesh_fs_params[21].xyz, _708, _709, fa_mesh_fs_params[20].w, _711, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _611 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _611 = -_611;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _611, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_50",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_150",
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
            "inst_name": "_197",
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
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_36",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
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
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _179 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_179 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_179 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_179 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos += fa_material_vs[0].xyz;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
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
            "inst_name": "_188",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
