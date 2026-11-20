{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    },
    {
      "name": "points",
      "binding": 1,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2582[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _541 = fa_mesh_fs_params[19].x < 0.0;\n    bool _548;\n    if (!_541)\n    {\n        _548 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return vec4(0.0);\n    }\n    vec4 _580 = vec4(world_pos, 1.0);\n    float _587 = dot(fa_mesh_fs_params[16], _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _609 = vec2(dot(fa_mesh_fs_params[14], _580), dot(fa_mesh_fs_params[15], _580)) / vec2(_587);\n    int _613 = int(fa_mesh_fs_params[18].x);\n    int _617 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _613 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _693 = fa_cluster_texel(param);\n    return ivec2(int(_693.x), int(_693.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3397 = fa_cluster_lookup(param);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3557 = fa_linear_to_srgb(param);\n        c = _3557;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3565 = fa_srgb_to_linear(param_1);\n            c = _3565;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _291;\n    if (i.front_facing)\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    vec3 _315 = normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    vec3 _343 = normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    vec3 _346;\n    if (i.front_facing)\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3596 = fa_tex_fix(param_2, param_3);\n    vec4 _4900 = base_t;\n    _4900.x = _3596.x;\n    _4900.y = _3596.y;\n    _4900.z = _3596.z;\n    base_t = _4900;\n    vec4 _3610 = (_4900 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4767 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3642 = fa_tex_fix(param_6, param_7);\n        vec3 _3645 = (_3642 * 2.0) - vec3(1.0);\n        vec2 _3650 = _3645.xy * fa_mesh_fs_params[6].x;\n        vec3 _4908 = _3645;\n        _4908.x = _3650.x;\n        _4908.y = _3650.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4908;\n        _4767 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3679 = fa_tex_fix(param_12, param_13);\n    vec4 _4911 = mrt;\n    _4911.x = _3679.x;\n    _4911.y = _3679.y;\n    _4911.z = _3679.z;\n    mrt = _4911;\n    vec4 _3707 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3707.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3719 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3749 = fa_tex_fix(param_20, param_21);\n    float _4772 = fa_mesh_fs_params[20].x;\n    float _4773 = fa_mesh_fs_params[20].y;\n    float _4776 = fa_mesh_fs_params[20].z;\n    float _4775 = fa_mesh_fs_params[21].w;\n    float _4778 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4772 *= _3719.y;\n            _4773 *= _3719.z;\n            _4775 *= _3707.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4776 *= mrt.x;\n            _4778 *= mrt.w;\n        }\n    }\n    return Surface(_3610.xyz, _3610.w, _4767, clamp(fa_mesh_fs_params[5].x * _3679.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3679.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3719.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3749), _4772, _4773, fa_mesh_fs_params[21].xyz, _4775, _4776, fa_mesh_fs_params[20].w, _4778, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _774 = rect.zw - rect.xy;\n    vec2 _778 = _774 * atlas;\n    vec2 _782 = ddx * _778;\n    vec2 _786 = ddy * _778;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _774), clamp(0.5 * log2(max(max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _821 = fa_mesh_fs_params[10].y < 0.5;\n    bool _828;\n    if (!_821)\n    {\n        _828 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    vec3 _834 = dFdx(world_pos);\n    vec3 _837 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _841 = fa_cluster_texel(param);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _855;\n    vec4 _859 = fa_light_texel(param_1);\n    vec2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    vec4 _871 = fa_light_texel(param_2);\n    float _872 = _871.x;\n    int _878 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _882 = int(_841.z);\n    vec3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        vec4 _918 = fa_light_texel(param_4);\n        if (((int(_918.w + 0.5) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        vec4 _933 = fa_light_texel(param_5);\n        int param_6 = _913 + 1;\n        vec4 _938 = fa_light_texel(param_6);\n        int param_7 = _913 + 2;\n        vec4 _943 = fa_light_texel(param_7);\n        vec3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        vec3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        vec3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = clamp(dot(geo_normal, normalize(_960)) * _918.z, 0.0, 1.0);\n        if (_1001 <= 0.0)\n        {\n            continue;\n        }\n        float _1021 = (clamp((0.5 - abs(_965)) * 10.0, 0.0, 1.0) * _1001) * _918.x;\n        vec2 _1029 = vec2(_951 + 0.5, 0.5 - _958);\n        vec2 _1039 = vec2(dot(_946, _834), dot(_953, _834));\n        vec2 _1049 = vec2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        vec4 _1054 = fa_light_texel(param_8);\n        int param_9 = _913 + 3;\n        vec4 _1059 = fa_light_texel(param_9);\n        int param_10 = _913 + 4;\n        vec4 _1064 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            vec4 param_11 = _1059;\n            vec2 param_12 = _1029;\n            vec2 param_13 = _862;\n            vec2 param_14 = _1039;\n            vec2 param_15 = _1049;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_872 > 0.5) && (_872 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1100 = fa_dc_to_linear(param_16);\n                vec4 _4823 = tx;\n                _4823.x = _1100.x;\n                _4823.y = _1100.y;\n                _4823.z = _1100.z;\n                tx = _4823;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1021 * tex_a) * _1054.w, 0.0, 1.0)));\n        if (_1064.z > _1064.x)\n        {\n            vec4 param_17 = _1064;\n            vec2 param_18 = _1029;\n            vec2 param_19 = _862;\n            vec2 param_20 = _1039;\n            vec2 param_21 = _1049;\n            vec4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_872 > 1.5)\n            {\n                vec3 param_22 = _1144.xyz;\n                vec3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            vec3 _1164 = (_1148 * 2.0) - vec3(1.0);\n            vec2 _1169 = _1164.xy * _918.y;\n            vec3 _1191 = (normalize(_946) * _1169.x) + (normalize(_953) * _1169.y);\n            vec3 _1194 = normalize(normal);\n            normal = normalize(mix(_1194, normalize((_1194 * max(_1164.z, 0.0500000007450580596923828125)) + (_1191 - (_1194 * dot(_1194, _1191)))), vec3(clamp(_1021 * (_1074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2507 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2515 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return mix(mix(_2582[_2587], _2582[_2587 + 1], _2531), mix(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4690 = false;\n    float _4691 = 1.0;\n    float _4692 = 1.0;\n    float _4693 = 1.0;\n    float _4694 = 0.0;\n    float _4695 = 0.0;\n    float _4696 = 0.0;\n    float _4697 = 0.0;\n    float _4699 = 1.0;\n    bool _4700 = false;\n    vec3 _4701 = vec3(0.0);\n    float _4702 = 1.0;\n    float _4703 = 1.0;\n    float _4704 = 1.0;\n    float _4705 = 0.0;\n    float _4706 = 0.0;\n    vec3 _4707 = vec3(1.0, 0.0, 0.0);\n    vec3 _4708 = vec3(0.0, 0.0, 1.0);\n    float _4709 = 1.0;\n    float _4710 = 1.0;\n    float _2660 = clamp(s.specular, 0.0, 1.0);\n    float _2664 = clamp(s.ior, 1.0, 3.0);\n    bool _2669 = (_2660 != 1.0) || (_2664 != 1.5);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0) / (_2664 + 1.0);\n        f0 = mix(min(vec3(_2687 * _2687) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2660, s.albedo, vec3(metallic));\n        _4691 = mix(_2660, 1.0, metallic);\n        _4690 = true;\n    }\n    float _2715 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2715 > 0.0)\n    {\n        float _2723 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4694 = _2715;\n        _4695 = _2723;\n        float _2730 = _2723 * _2723;\n        _4696 = _2730;\n        _4697 = _2730 * _2730;\n        float _2742 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4699 = _2742;\n        _4692 = 1.0 - (_2715 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2742, 0.0, 1.0), 5.0))));\n        _4690 = true;\n    }\n    vec3 _2762 = max(s.sheen_color, vec3(0.0));\n    float _2771 = max(_2762.x, max(_2762.y, _2762.z));\n    if (_2771 > 0.0)\n    {\n        float _2779 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4700 = true;\n        _4701 = _2762;\n        _4702 = _2779;\n        _4703 = _2779 * _2779;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4705 = _2796;\n        _4704 = 1.0 - min(_2771 * _2796, 1.0);\n        _4690 = true;\n    }\n    _4693 = _4692 * _4704;\n    float _2815 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2815 != 0.0)\n    {\n        vec3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2843 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2843.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2843.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2843.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2847 = t;\n        vec3 _2848 = normalize(_2847);\n        t = _2848;\n        vec3 _2873 = normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4707 = _2873;\n        _4708 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = mix(_2883, 1.0, _2815 * _2815);\n        bool _2891 = _2815 > 0.0;\n        _4709 = _2891 ? _2889 : _2883;\n        _4710 = _2891 ? _2883 : _2889;\n        _4706 = _2815;\n        _4690 = true;\n    }\n    return FaLayers(_4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, i.world_normal, _4699, _4700, _4701, _4702, _4703, _4704, _4705, _4706, _4707, _4708, _4709, _4710);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _410 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _416 = fa_light_texel(param_1);\n    float _419 = _416.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _425 = _419 < 0.5;\n    vec3 l;\n    if (_425)\n    {\n        l = normalize(_410.xyz);\n    }\n    else\n    {\n        vec3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / vec3(max(_439, 9.9999997473787516355514526367188e-05));\n        float _454 = _439 / max(_410.w, 0.001000000047497451305389404296875);\n        float _460 = clamp(1.0 - (_454 * _454), 0.0, 1.0);\n        atten = _460 * _460;\n        if (_419 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _474 = fa_light_texel(param_2);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _490 = fa_light_texel(param_3);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5)\n            {\n                cos_inner = mix(_484, 1.0, 0.25);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _416.xyz * atten, atten, 1.0, dist, _522);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1290 = fa_shadows[24].w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1);\n    float _1327;\n    if (conv.x < 0.5)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1373 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1387 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            vec2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            vec2 param_6 = uv + (_1406 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        vec2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1481 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1462);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1523 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1528 = clamp(dot(n, l), 0.0, 1.0);\n    float _1534 = sqrt(1.0 - (_1528 * _1528));\n    float _1541 = min(_1534 / max(_1528, 0.20000000298023223876953125), 4.0);\n    float _1546;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1546 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1546 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1571 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1546 * _1534)), 1.0);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < fa_shadows[ci * 1 + 16].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0;\n    }\n    float _1624;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1624 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1624 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1571.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1571.z - ((_1624 * (1.0 + (0.5 * _1541))) / _1523);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1541, 3.0)) * 0.5) / _1523;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2051 = int(fa_shadows[25].x + 0.5);\n    if (_2051 < 1)\n    {\n        return 1.0;\n    }\n    float _2066 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2133;\n        if (_2133 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2158 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2177 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2158, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2188 = clamp((_2066 - (fa_shadow_split_at(param_7) - _2177)) / _2177, 0.0, 1.0);\n        if (_2188 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2209;\n                if (_2209 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1682 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1703 = fa_light_texel(param);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1713 = int(_1704 + 0.5);\n    int param_1 = _1713;\n    vec4 _1717 = fa_light_texel(param_1);\n    int param_2 = _1713 + 1;\n    vec4 _1722 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0)\n    {\n        float _1742 = 1.0 - smoothstep(0.75 * _1725, _1725, length(world - fa_shadows[27].xyz));\n        fade = _1742;\n        if (_1742 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1761 = world - fa_light_texel(param_3).xyz;\n        vec3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    vec4 _1824 = fa_light_texel(param_6);\n    int param_7 = _1810 + 4;\n    vec4 _1829 = fa_light_texel(param_7);\n    int param_8 = _1810 + 5;\n    vec4 _1834 = fa_light_texel(param_8);\n    float _1846 = _1834.x * max(dot(_1824, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1851 = clamp(dot(n, l), 0.0, 1.0);\n    float _1874 = clamp(dot(n, _1824.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1897 = min(sqrt(1.0 - (_1874 * _1874)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1824, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5 * _1846;\n    }\n    vec4 _1922 = vec4(world + (n * (_1902 * sqrt(1.0 - (_1851 * _1851)))), 1.0);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0;\n    }\n    vec2 _1944 = vec2(dot(fa_light_texel(param_4), _1922), dot(fa_light_texel(param_5), _1922)) / vec2(_1926);\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5 * _1846;\n    }\n    vec2 param_10 = _1944;\n    vec4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0 + (0.5 * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0;\n    float param_15 = _1834.z * 0.25;\n    float param_16 = (_1846 * min(_1897, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5);\n    float param_19 = _1717.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3424 = fa_lm.z > 0.5;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3);\n    vec3 _4752 = _3452.direction;\n    vec3 _4747 = _3452.color;\n    float _4754 = _3452.attenuation;\n    float _4749 = _3452.shadow;\n    int _4757 = _3452.type;\n    if ((_4757 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4752;\n        float _3466 = fa_shadow_factor(param_4, param_5);\n        _4749 = _3466;\n        _4747 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4757 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4754 > 0.0;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4752;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4749 = _3495;\n            _4747 *= _3495;\n        }\n    }\n    return LightSample(_4752, _4747, _4754, _4749, _3452._distance, _4757);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3057) * _3057);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3138 = 1.0 / alpha;\n    return ((2.0 + _3138) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3138)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3249) * _3249);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3170);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3170));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3322 = max(dot(L.nc, l), 0.0);\n        float _3328 = max(dot(L.nc, h), 0.0);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3337) * _3337)) * (0.5 / max(mix((2.0 * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3322)) * _3322);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2439 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2442 = _2439.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2442 * _2442, exp2((-9.27999973297119140625) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625 * _2345;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2345)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2375, 0.0500000007450580596923828125 + _2375, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2345 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2924;\n        if (L.aniso >= 0.0)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2924, v), _2924), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2957 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2957.x) + (vec3(L.f90) * _2957.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3012 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2481 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2481.x) + vec3(_2481.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2233 = int(fa_shadows[25].x + 0.5);\n    float _2243 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4469 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4469 = -_4469;\n    }\n    vec3 _3889 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n    Surface _3897 = fa_standard_surface(param_1);\n    vec3 _4500 = _3897.albedo;\n    float _4501 = _3897.alpha;\n    vec3 _4502 = _3897.normal;\n    float _4503 = _3897.metallic;\n    float _4504 = _3897.roughness;\n    float _4505 = _3897.occlusion;\n    vec3 _4506 = _3897.emission;\n    float _4507 = _3897.clearcoat;\n    float _4508 = _3897.clearcoat_roughness;\n    vec3 _4509 = _3897.sheen_color;\n    float _4510 = _3897.sheen_roughness;\n    float _4511 = _3897.anisotropy;\n    float _4512 = _3897.anisotropy_rotation;\n    float _4513 = _3897.specular;\n    float _4514 = _3897.ior;\n    vec3 _4515 = _3897.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n    Surface param_3 = _3897;\n    surface(param_2, param_3);\n    _4500 = param_3.albedo;\n    _4501 = param_3.alpha;\n    _4502 = param_3.normal;\n    _4503 = param_3.metallic;\n    _4504 = param_3.roughness;\n    _4505 = param_3.occlusion;\n    _4506 = param_3.emission;\n    _4507 = param_3.clearcoat;\n    _4508 = param_3.clearcoat_roughness;\n    _4509 = param_3.sheen_color;\n    _4510 = param_3.sheen_roughness;\n    _4511 = param_3.anisotropy;\n    _4512 = param_3.anisotropy_rotation;\n    _4513 = param_3.specular;\n    _4514 = param_3.ior;\n    _4515 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4469;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4500 = param_6;\n    _4502 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4500;\n    }\n    else\n    {\n        vec3 _3936 = normalize(_4502);\n        float _3943 = clamp(_4503, 0.0, 1.0);\n        float _3947 = clamp(_4504, 0.0500000007450580596923828125, 1.0);\n        float _3951 = _3947 * _3947;\n        float _3955 = _3951 * _3951;\n        float _3960 = max(dot(_3936, _3889), 9.9999997473787516355514526367188e-05);\n        vec3 _3966 = _4500 * (1.0 - _3943);\n        vec3 _3973 = mix(vec3(0.039999999105930328369140625), _4500, vec3(_3943));\n        vec3 f0 = _3973;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n        Surface param_9 = Surface(_4500, _4501, _4502, _4503, _4504, _4505, _4506, _4507, _4508, _4509, _4510, _4511, _4512, _4513, _4514, _4515);\n        vec3 param_10 = _3936;\n        vec3 param_11 = _3889;\n        float param_12 = _3943;\n        float param_13 = _3947;\n        vec3 param_14 = _3973;\n        FaLayers _3989 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _3936;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _3966) * _4505;\n        if (_3989.on)\n        {\n            lit *= _3989.base_scale;\n        }\n        int _4011 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4011; ln++)\n        {\n            int param_16 = ln;\n            int _4024 = fa_cl_light(param_16);\n            bool _4027 = fa_lm.z > 0.5;\n            bool _4033;\n            if (_4027)\n            {\n                int param_17 = _4024;\n                _4033 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4033 = _4027;\n            }\n            if (_4033)\n            {\n                continue;\n            }\n            int param_18 = _4024;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4469;\n            LightSample _4045 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4674 = _4045.direction;\n            float _4053 = max(dot(_3936, _4674), 0.0);\n            float _4059 = _4045.attenuation * _4045.shadow;\n            vec3 _4064 = normalize(_4674 + _3889);\n            float _4069 = max(dot(_3936, _4064), 0.0);\n            float _4074 = max(dot(_3889, _4064), 0.0);\n            if (_3989.on)\n            {\n                FaLayers param_21 = _3989;\n                vec3 param_22 = _3966;\n                vec3 param_23 = f0;\n                vec3 param_24 = _3936;\n                vec3 param_25 = _3889;\n                vec3 param_26 = _4674;\n                vec3 param_27 = _4064;\n                float param_28 = _4053;\n                float param_29 = _3960;\n                float param_30 = _4069;\n                float param_31 = _4074;\n                float param_32 = _3951;\n                float param_33 = _3955;\n                int param_34 = _4024;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4059));\n            }\n            else\n            {\n                float _4122 = ((_4069 * _4069) * (_3955 - 1.0)) + 1.0;\n                int param_35 = _4024;\n                lit += (((_3966 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4074, 5.0))) * (((_3955 / ((3.1415927410125732421875 * _4122) * _4122)) * (0.5 / max(mix((2.0 * _4053) * _3960, _4053 + _3960, _3951), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4053))) * fa_light_rgb(param_35)) * (_4053 * _4059));\n            }\n        }\n        if (_3989.on)\n        {\n            FaLayers param_36 = _3989;\n            vec3 param_37 = _3936;\n            vec3 param_38 = _3889;\n            vec3 param_39 = f0;\n            float param_40 = _3947;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4505);\n        }\n        else\n        {\n            vec3 param_41 = _3936;\n            vec3 param_42 = _3889;\n            vec3 param_43 = f0;\n            float param_44 = _3947;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4505);\n        }\n        result = lit;\n    }\n    vec3 _4215 = result;\n    vec3 _4216 = _4215 + _4506;\n    result = _4216;\n    vec3 param_45 = _4216;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4225 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4232;\n    if (!_4225)\n    {\n        _4232 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4232 = _4225;\n    }\n    if (_4232)\n    {\n        vec3 _4241 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4247 = dot(_4241, fa_mesh_fs_params[9].xyz);\n        bool _4251 = fa_mesh_fs_params[9].w > 0.5;\n        float _4252;\n        if (_4251)\n        {\n            _4252 = _4247;\n        }\n        else\n        {\n            _4252 = length(_4241);\n        }\n        float _4264 = _4252 - fa_mesh_fs_params[8].x;\n        if (_4264 > 0.0)\n        {\n            float _4273 = fa_mesh_fs_params[7].w * _4264;\n            float tau = _4273 * _4273;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4289;\n                if (_4251)\n                {\n                    _4289 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4247);\n                }\n                else\n                {\n                    _4289 = fa_mesh_fs_params[0].y;\n                }\n                float _4310 = mix(_4289, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4252, 0.0, 1.0));\n                float _4314 = fa_world_pos.y - _4310;\n                float _4319 = _4310 - fa_mesh_fs_params[8].z;\n                float _4324 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4327 = _4319 <= 0.0;\n                bool _4328 = !_4327;\n                bool _4334;\n                if (_4328)\n                {\n                    _4334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4334 = _4327;\n                }\n                float _4335;\n                if (_4334)\n                {\n                    _4335 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4335 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4319, 80.0));\n                }\n                bool _4362;\n                if (_4328)\n                {\n                    _4362 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4362 = _4327;\n                }\n                float _4363;\n                if (_4362)\n                {\n                    _4363 = fa_mesh_fs_params[8].y * _4319;\n                }\n                else\n                {\n                    _4363 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4319, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4388 = _4324 <= 0.0;\n                bool _4395;\n                if (!_4388)\n                {\n                    _4395 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4395 = _4388;\n                }\n                float _4396;\n                if (_4395)\n                {\n                    _4396 = fa_mesh_fs_params[8].y * _4324;\n                }\n                else\n                {\n                    _4396 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4324, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4423;\n                if (abs(_4314) < 0.001000000047497451305389404296875)\n                {\n                    _4423 = _4335;\n                }\n                else\n                {\n                    _4423 = (_4396 - _4363) / _4314;\n                }\n                tau += (_4264 * max(_4423, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4501);\n}\n\n",
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
            "inst_name": "_182",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_252",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
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
            "inst_name": "_1276",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2582[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _541 = fa_mesh_fs_params[19].x < 0.0;\n    bool _548;\n    if (!_541)\n    {\n        _548 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _548 = _541;\n    }\n    bool _556;\n    if (!_548)\n    {\n        _556 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    bool _563;\n    if (!_556)\n    {\n        _563 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _563 = _556;\n    }\n    bool _570;\n    if (!_563)\n    {\n        _570 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _570 = _563;\n    }\n    if (_570)\n    {\n        return vec4(0.0);\n    }\n    vec4 _580 = vec4(world_pos, 1.0);\n    float _587 = dot(fa_mesh_fs_params[16], _580);\n    if (!(_587 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _609 = vec2(dot(fa_mesh_fs_params[14], _580), dot(fa_mesh_fs_params[15], _580)) / vec2(_587);\n    int _613 = int(fa_mesh_fs_params[18].x);\n    int _617 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _617) + clamp(int(floor(((_609.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _617 - 1)) * _613)) + clamp(int(floor(((_609.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _613 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _693 = fa_cluster_texel(param);\n    return ivec2(int(_693.x), int(_693.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3397 = fa_cluster_lookup(param);\n    fa_cl_slot = _3397.x;\n    fa_cl_local = _3397.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3557 = fa_linear_to_srgb(param);\n        c = _3557;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3565 = fa_srgb_to_linear(param_1);\n            c = _3565;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _291;\n    if (i.front_facing)\n    {\n        _291 = i.world_normal;\n    }\n    else\n    {\n        _291 = -i.world_normal;\n    }\n    vec3 _315 = normalize(i.world_tangent.xyz - (_291 * dot(_291, i.world_tangent.xyz)));\n    vec3 _343 = normalize(((_315 * m.x) + ((cross(_291, _315) * i.world_tangent.w) * m.y)) + (_291 * m.z));\n    vec3 _346;\n    if (i.front_facing)\n    {\n        _346 = _343;\n    }\n    else\n    {\n        _346 = -_343;\n    }\n    return _346;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3596 = fa_tex_fix(param_2, param_3);\n    vec4 _4900 = base_t;\n    _4900.x = _3596.x;\n    _4900.y = _3596.y;\n    _4900.z = _3596.z;\n    base_t = _4900;\n    vec4 _3610 = (_4900 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4767 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3642 = fa_tex_fix(param_6, param_7);\n        vec3 _3645 = (_3642 * 2.0) - vec3(1.0);\n        vec2 _3650 = _3645.xy * fa_mesh_fs_params[6].x;\n        vec3 _4908 = _3645;\n        _4908.x = _3650.x;\n        _4908.y = _3650.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4908;\n        _4767 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3679 = fa_tex_fix(param_12, param_13);\n    vec4 _4911 = mrt;\n    _4911.x = _3679.x;\n    _4911.y = _3679.y;\n    _4911.z = _3679.z;\n    mrt = _4911;\n    vec4 _3707 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3707.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3719 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3749 = fa_tex_fix(param_20, param_21);\n    float _4772 = fa_mesh_fs_params[20].x;\n    float _4773 = fa_mesh_fs_params[20].y;\n    float _4776 = fa_mesh_fs_params[20].z;\n    float _4775 = fa_mesh_fs_params[21].w;\n    float _4778 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4772 *= _3719.y;\n            _4773 *= _3719.z;\n            _4775 *= _3707.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4776 *= mrt.x;\n            _4778 *= mrt.w;\n        }\n    }\n    return Surface(_3610.xyz, _3610.w, _4767, clamp(fa_mesh_fs_params[5].x * _3679.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3679.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3719.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3749), _4772, _4773, fa_mesh_fs_params[21].xyz, _4775, _4776, fa_mesh_fs_params[20].w, _4778, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _774 = rect.zw - rect.xy;\n    vec2 _778 = _774 * atlas;\n    vec2 _782 = ddx * _778;\n    vec2 _786 = ddy * _778;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _774), clamp(0.5 * log2(max(max(dot(_782, _782), dot(_786, _786)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _821 = fa_mesh_fs_params[10].y < 0.5;\n    bool _828;\n    if (!_821)\n    {\n        _828 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _828 = _821;\n    }\n    if (_828)\n    {\n        return;\n    }\n    vec3 _834 = dFdx(world_pos);\n    vec3 _837 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _841 = fa_cluster_texel(param);\n    int _845 = int(_841.w);\n    if (_845 < 1)\n    {\n        return;\n    }\n    int _855 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _855;\n    vec4 _859 = fa_light_texel(param_1);\n    vec2 _862 = _859.yz;\n    int _866 = int(_859.w);\n    int param_2 = _855 + 1;\n    vec4 _871 = fa_light_texel(param_2);\n    float _872 = _871.x;\n    int _878 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _882 = int(_841.z);\n    vec3 _1148;\n    for (int k = 0; k < _845; k++)\n    {\n        int _895 = _882 + k;\n        int param_3 = _866 + (_895 >> 2);\n        int _913 = (_855 + 2) + (int(fa_light_texel(param_3)[_895 & 3]) * 7);\n        int param_4 = _913 + 6;\n        vec4 _918 = fa_light_texel(param_4);\n        if (((int(_918.w + 0.5) >> _878) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _913;\n        vec4 _933 = fa_light_texel(param_5);\n        int param_6 = _913 + 1;\n        vec4 _938 = fa_light_texel(param_6);\n        int param_7 = _913 + 2;\n        vec4 _943 = fa_light_texel(param_7);\n        vec3 _946 = _933.xyz;\n        float _951 = dot(_946, world_pos) + _933.w;\n        vec3 _953 = _938.xyz;\n        float _958 = dot(_953, world_pos) + _938.w;\n        vec3 _960 = _943.xyz;\n        float _965 = dot(_960, world_pos) + _943.w;\n        bool _970 = abs(_951) > 0.5;\n        bool _978;\n        if (!_970)\n        {\n            _978 = abs(_958) > 0.5;\n        }\n        else\n        {\n            _978 = _970;\n        }\n        bool _986;\n        if (!_978)\n        {\n            _986 = abs(_965) > 0.5;\n        }\n        else\n        {\n            _986 = _978;\n        }\n        if (_986)\n        {\n            continue;\n        }\n        float _1001 = clamp(dot(geo_normal, normalize(_960)) * _918.z, 0.0, 1.0);\n        if (_1001 <= 0.0)\n        {\n            continue;\n        }\n        float _1021 = (clamp((0.5 - abs(_965)) * 10.0, 0.0, 1.0) * _1001) * _918.x;\n        vec2 _1029 = vec2(_951 + 0.5, 0.5 - _958);\n        vec2 _1039 = vec2(dot(_946, _834), dot(_953, _834));\n        vec2 _1049 = vec2(dot(_946, _837), dot(_953, _837));\n        int param_8 = _913 + 5;\n        vec4 _1054 = fa_light_texel(param_8);\n        int param_9 = _913 + 3;\n        vec4 _1059 = fa_light_texel(param_9);\n        int param_10 = _913 + 4;\n        vec4 _1064 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1054.xyz;\n        bool _1074 = _1059.z > _1059.x;\n        if (_1074)\n        {\n            vec4 param_11 = _1059;\n            vec2 param_12 = _1029;\n            vec2 param_13 = _862;\n            vec2 param_14 = _1039;\n            vec2 param_15 = _1049;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_872 > 0.5) && (_872 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1100 = fa_dc_to_linear(param_16);\n                vec4 _4823 = tx;\n                _4823.x = _1100.x;\n                _4823.y = _1100.y;\n                _4823.z = _1100.z;\n                tx = _4823;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1021 * tex_a) * _1054.w, 0.0, 1.0)));\n        if (_1064.z > _1064.x)\n        {\n            vec4 param_17 = _1064;\n            vec2 param_18 = _1029;\n            vec2 param_19 = _862;\n            vec2 param_20 = _1039;\n            vec2 param_21 = _1049;\n            vec4 _1144 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_872 > 1.5)\n            {\n                vec3 param_22 = _1144.xyz;\n                vec3 _1154 = fa_dc_to_srgb(param_22);\n                _1148 = _1154;\n            }\n            else\n            {\n                _1148 = _1144.xyz;\n            }\n            vec3 _1164 = (_1148 * 2.0) - vec3(1.0);\n            vec2 _1169 = _1164.xy * _918.y;\n            vec3 _1191 = (normalize(_946) * _1169.x) + (normalize(_953) * _1169.y);\n            vec3 _1194 = normalize(normal);\n            normal = normalize(mix(_1194, normalize((_1194 * max(_1164.z, 0.0500000007450580596923828125)) + (_1191 - (_1194 * dot(_1194, _1191)))), vec3(clamp(_1021 * (_1074 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2507 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2515 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2518 = int(_2507);\n    int _2521 = int(_2515);\n    float _2531 = _2515 - float(_2521);\n    int _2587 = (_2518 * 9) + _2521;\n    int _2607 = ((_2518 + 1) * 9) + _2521;\n    return mix(mix(_2582[_2587], _2582[_2587 + 1], _2531), mix(_2582[_2607], _2582[_2607 + 1], _2531), _2507 - float(_2518));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4690 = false;\n    float _4691 = 1.0;\n    float _4692 = 1.0;\n    float _4693 = 1.0;\n    float _4694 = 0.0;\n    float _4695 = 0.0;\n    float _4696 = 0.0;\n    float _4697 = 0.0;\n    float _4699 = 1.0;\n    bool _4700 = false;\n    vec3 _4701 = vec3(0.0);\n    float _4702 = 1.0;\n    float _4703 = 1.0;\n    float _4704 = 1.0;\n    float _4705 = 0.0;\n    float _4706 = 0.0;\n    vec3 _4707 = vec3(1.0, 0.0, 0.0);\n    vec3 _4708 = vec3(0.0, 0.0, 1.0);\n    float _4709 = 1.0;\n    float _4710 = 1.0;\n    float _2660 = clamp(s.specular, 0.0, 1.0);\n    float _2664 = clamp(s.ior, 1.0, 3.0);\n    bool _2669 = (_2660 != 1.0) || (_2664 != 1.5);\n    bool _2679;\n    if (!_2669)\n    {\n        _2679 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2679 = _2669;\n    }\n    if (_2679)\n    {\n        float _2687 = (_2664 - 1.0) / (_2664 + 1.0);\n        f0 = mix(min(vec3(_2687 * _2687) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2660, s.albedo, vec3(metallic));\n        _4691 = mix(_2660, 1.0, metallic);\n        _4690 = true;\n    }\n    float _2715 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2715 > 0.0)\n    {\n        float _2723 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4694 = _2715;\n        _4695 = _2723;\n        float _2730 = _2723 * _2723;\n        _4696 = _2730;\n        _4697 = _2730 * _2730;\n        float _2742 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4699 = _2742;\n        _4692 = 1.0 - (_2715 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2742, 0.0, 1.0), 5.0))));\n        _4690 = true;\n    }\n    vec3 _2762 = max(s.sheen_color, vec3(0.0));\n    float _2771 = max(_2762.x, max(_2762.y, _2762.z));\n    if (_2771 > 0.0)\n    {\n        float _2779 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4700 = true;\n        _4701 = _2762;\n        _4702 = _2779;\n        _4703 = _2779 * _2779;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2779;\n        float _2796 = fa_sheen_albedo(param, param_1);\n        _4705 = _2796;\n        _4704 = 1.0 - min(_2771 * _2796, 1.0);\n        _4690 = true;\n    }\n    _4693 = _4692 * _4704;\n    float _2815 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2815 != 0.0)\n    {\n        vec3 _2830 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2830;\n        if (dot(_2830, _2830) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2843 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2843.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2843.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2843.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2847 = t;\n        vec3 _2848 = normalize(_2847);\n        t = _2848;\n        vec3 _2873 = normalize((_2848 * cos(s.anisotropy_rotation)) + ((cross(n, _2848) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4707 = _2873;\n        _4708 = cross(n, _2873);\n        float _2883 = roughness * roughness;\n        float _2889 = mix(_2883, 1.0, _2815 * _2815);\n        bool _2891 = _2815 > 0.0;\n        _4709 = _2891 ? _2889 : _2883;\n        _4710 = _2891 ? _2883 : _2889;\n        _4706 = _2815;\n        _4690 = true;\n    }\n    return FaLayers(_4690, _4691, _4692, _4693, _4694, _4695, _4696, _4697, i.world_normal, _4699, _4700, _4701, _4702, _4703, _4704, _4705, _4706, _4707, _4708, _4709, _4710);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _410 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _416 = fa_light_texel(param_1);\n    float _419 = _416.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _425 = _419 < 0.5;\n    vec3 l;\n    if (_425)\n    {\n        l = normalize(_410.xyz);\n    }\n    else\n    {\n        vec3 _437 = _410.xyz - world_pos;\n        float _439 = length(_437);\n        dist = _439;\n        l = _437 / vec3(max(_439, 9.9999997473787516355514526367188e-05));\n        float _454 = _439 / max(_410.w, 0.001000000047497451305389404296875);\n        float _460 = clamp(1.0 - (_454 * _454), 0.0, 1.0);\n        atten = _460 * _460;\n        if (_419 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _474 = fa_light_texel(param_2);\n            float _484 = _474.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _490 = fa_light_texel(param_3);\n            float _491 = _490.x;\n            float cos_inner = _491;\n            if (_491 > 1.5)\n            {\n                cos_inner = mix(_484, 1.0, 0.25);\n            }\n            atten *= smoothstep(_484, cos_inner, dot(-l, normalize(_474.xyz)));\n        }\n    }\n    int _522;\n    if (_425)\n    {\n        _522 = 0;\n    }\n    else\n    {\n        _522 = (_419 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _416.xyz * atten, atten, 1.0, dist, _522);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1266;\n    if (i == 0)\n    {\n        _1266 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1282;\n        if (i == 1)\n        {\n            _1282 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1290;\n            if (i == 2)\n            {\n                _1290 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1290 = fa_shadows[24].w;\n            }\n            _1282 = _1290;\n        }\n        _1266 = _1282;\n    }\n    return _1266;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1323 = fa_shadow_depth(param, param_1);\n    float _1327;\n    if (conv.x < 0.5)\n    {\n        _1327 = _1323;\n    }\n    else\n    {\n        _1327 = (conv.y * conv.z) / (conv.z - (_1323 * (conv.z - conv.y)));\n    }\n    return _1327;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1254 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1254), sin(_1254)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1373 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1387 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1373;\n            vec2 _1406 = fa_shadow_vogel(param_3, param_4, param_5) * _1387;\n            vec2 param_6 = uv + (_1406 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1418 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1418 < (zr - (length(_1406) * plane)))\n            {\n                sum += _1418;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1462 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1462; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1462;\n        float param_11 = _1373;\n        vec2 _1481 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1481 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1481) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1462);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1523 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1528 = clamp(dot(n, l), 0.0, 1.0);\n    float _1534 = sqrt(1.0 - (_1528 * _1528));\n    float _1541 = min(_1534 / max(_1528, 0.20000000298023223876953125), 4.0);\n    float _1546;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1546 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1546 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1571 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1546 * _1534)), 1.0);\n    float _1578 = _1571.x;\n    bool _1581 = _1578 < fa_shadows[ci * 1 + 16].x;\n    bool _1590;\n    if (!_1581)\n    {\n        _1590 = _1578 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1590 = _1581;\n    }\n    bool _1599;\n    if (!_1590)\n    {\n        _1599 = _1571.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1599 = _1590;\n    }\n    bool _1608;\n    if (!_1599)\n    {\n        _1608 = _1571.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1608 = _1599;\n    }\n    bool _1615;\n    if (!_1608)\n    {\n        _1615 = _1571.z > 1.0;\n    }\n    else\n    {\n        _1615 = _1608;\n    }\n    if (_1615)\n    {\n        return -1.0;\n    }\n    float _1624;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1624 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1624 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1571.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1571.z - ((_1624 * (1.0 + (0.5 * _1541))) / _1523);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1523;\n    float param_5 = _1523 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1541, 3.0)) * 0.5) / _1523;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2051 = int(fa_shadows[25].x + 0.5);\n    if (_2051 < 1)\n    {\n        return 1.0;\n    }\n    float _2066 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2051 - 1;\n    if (_2066 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2078 = _2051 > 1;\n    bool _2085;\n    if (_2078)\n    {\n        _2085 = _2066 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2085 = _2078;\n    }\n    if (_2085)\n    {\n        ci = 1;\n    }\n    bool _2089 = _2051 > 2;\n    bool _2096;\n    if (_2089)\n    {\n        _2096 = _2066 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2096 = _2089;\n    }\n    if (_2096)\n    {\n        ci = 2;\n    }\n    bool _2100 = _2051 > 3;\n    bool _2107;\n    if (_2100)\n    {\n        _2107 = _2066 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2107 = _2100;\n    }\n    if (_2107)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2051)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2133 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2133;\n        if (_2133 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2158;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2158 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2158 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2177 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2158, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2188 = clamp((_2066 - (fa_shadow_split_at(param_7) - _2177)) / _2177, 0.0, 1.0);\n        if (_2188 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2051)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2209 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2209;\n                if (_2209 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2188);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1682 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1690;\n    if (!_1682)\n    {\n        _1690 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1690 = _1682;\n    }\n    if (_1690)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1703 = fa_light_texel(param);\n    float _1704 = _1703.x;\n    if (_1704 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1713 = int(_1704 + 0.5);\n    int param_1 = _1713;\n    vec4 _1717 = fa_light_texel(param_1);\n    int param_2 = _1713 + 1;\n    vec4 _1722 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1725 = _1717.y;\n    if (_1725 > 0.0)\n    {\n        float _1742 = 1.0 - smoothstep(0.75 * _1725, _1725, length(world - fa_shadows[27].xyz));\n        fade = _1742;\n        if (_1742 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1717.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1761 = world - fa_light_texel(param_3).xyz;\n        vec3 _1764 = abs(_1761);\n        float _1766 = _1764.x;\n        float _1768 = _1764.y;\n        bool _1769 = _1766 >= _1768;\n        bool _1777;\n        if (_1769)\n        {\n            _1777 = _1766 >= _1764.z;\n        }\n        else\n        {\n            _1777 = _1769;\n        }\n        int _1778;\n        if (_1777)\n        {\n            _1778 = (_1761.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1791;\n            if (_1768 >= _1764.z)\n            {\n                _1791 = (_1761.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1791 = (_1761.z > 0.0) ? 4 : 5;\n            }\n            _1778 = _1791;\n        }\n        face = _1778;\n    }\n    int _1810 = (_1713 + 2) + (face * 6);\n    int param_4 = _1810;\n    int param_5 = _1810 + 1;\n    int param_6 = _1810 + 3;\n    vec4 _1824 = fa_light_texel(param_6);\n    int param_7 = _1810 + 4;\n    vec4 _1829 = fa_light_texel(param_7);\n    int param_8 = _1810 + 5;\n    vec4 _1834 = fa_light_texel(param_8);\n    float _1846 = _1834.x * max(dot(_1824, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1851 = clamp(dot(n, l), 0.0, 1.0);\n    float _1874 = clamp(dot(n, _1824.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1897 = min(sqrt(1.0 - (_1874 * _1874)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1824, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1900 = _1722.y;\n    float _1902;\n    if (_1900 > 0.0)\n    {\n        _1902 = _1900;\n    }\n    else\n    {\n        _1902 = 1.5 * _1846;\n    }\n    vec4 _1922 = vec4(world + (n * (_1902 * sqrt(1.0 - (_1851 * _1851)))), 1.0);\n    float _1926 = dot(_1824, _1922);\n    float _1929 = _1834.y;\n    if (_1926 < _1929)\n    {\n        return 1.0;\n    }\n    vec2 _1944 = vec2(dot(fa_light_texel(param_4), _1922), dot(fa_light_texel(param_5), _1922)) / vec2(_1926);\n    float _1946 = _1944.x;\n    bool _1949 = _1946 < _1829.x;\n    bool _1958;\n    if (!_1949)\n    {\n        _1958 = _1946 > _1829.z;\n    }\n    else\n    {\n        _1958 = _1949;\n    }\n    bool _1967;\n    if (!_1958)\n    {\n        _1967 = _1944.y < _1829.y;\n    }\n    else\n    {\n        _1967 = _1958;\n    }\n    bool _1976;\n    if (!_1967)\n    {\n        _1976 = _1944.y > _1829.w;\n    }\n    else\n    {\n        _1976 = _1967;\n    }\n    if (_1976)\n    {\n        return 1.0;\n    }\n    float _1982 = _1722.x;\n    float _1984;\n    if (_1982 > 0.0)\n    {\n        _1984 = _1982;\n    }\n    else\n    {\n        _1984 = 1.5 * _1846;\n    }\n    vec2 param_10 = _1944;\n    vec4 param_11 = _1829;\n    float param_12 = _1926 - (_1984 * (1.0 + (0.5 * _1897)));\n    float param_13 = _1846;\n    float param_14 = 1.0;\n    float param_15 = _1834.z * 0.25;\n    float param_16 = (_1846 * min(_1897, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1929, _1834.z);\n    int param_18 = int(_1717.z + 0.5);\n    float param_19 = _1717.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3424 = fa_lm.z > 0.5;\n    bool _3430;\n    if (_3424)\n    {\n        int param = li;\n        _3430 = fa_light_baked(param);\n    }\n    else\n    {\n        _3430 = _3424;\n    }\n    if (_3430)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3452 = fa_light_sample(param_2, param_3);\n    vec3 _4752 = _3452.direction;\n    vec3 _4747 = _3452.color;\n    float _4754 = _3452.attenuation;\n    float _4749 = _3452.shadow;\n    int _4757 = _3452.type;\n    if ((_4757 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4752;\n        float _3466 = fa_shadow_factor(param_4, param_5);\n        _4749 = _3466;\n        _4747 *= _3466;\n    }\n    else\n    {\n        bool _3477 = _4757 != 0;\n        bool _3483;\n        if (_3477)\n        {\n            _3483 = _4754 > 0.0;\n        }\n        else\n        {\n            _3483 = _3477;\n        }\n        if (_3483)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4752;\n            float _3495 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4749 = _3495;\n            _4747 *= _3495;\n        }\n    }\n    return LightSample(_4752, _4747, _4754, _4749, _3452._distance, _4757);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3041 = tdh / at;\n    float _3045 = bdh / ab;\n    float _3057 = ((_3041 * _3041) + (_3045 * _3045)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3057) * _3057);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3138 = 1.0 / alpha;\n    return ((2.0 + _3138) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3138)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3170 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3249 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3249) * _3249);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3170);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3170));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3322 = max(dot(L.nc, l), 0.0);\n        float _3328 = max(dot(L.nc, h), 0.0);\n        float _3337 = ((_3328 * _3328) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3337) * _3337)) * (0.5 / max(mix((2.0 * _3322) * L.coat_ndv, _3322 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3322)) * _3322);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2439 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2442 = _2439.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2442 * _2442, exp2((-9.27999973297119140625) * ndv)) * _2442) + _2439.y)) + _2439.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2345 = rough * rough;\n    float _2375 = 0.60000002384185791015625 * _2345;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2345)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2375, 0.0500000007450580596923828125 + _2375, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2345 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2924;\n        if (L.aniso >= 0.0)\n        {\n            _2924 = L.b;\n        }\n        else\n        {\n            _2924 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2924, v), _2924), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2957 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2957.x) + (vec3(L.f90) * _2957.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3012 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3012.x) + _3012.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2481 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2481.x) + vec3(_2481.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2233 = int(fa_shadows[25].x + 0.5);\n    float _2243 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2248 = _2233 > 0;\n    bool _2257;\n    if (_2248)\n    {\n        int param = _2233 - 1;\n        _2257 = _2243 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2257 = _2248;\n    }\n    if (_2257)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2264 = _2233 > 1;\n        bool _2271;\n        if (_2264)\n        {\n            _2271 = _2243 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2271 = _2264;\n        }\n        if (_2271)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2277 = _2233 > 2;\n        bool _2284;\n        if (_2277)\n        {\n            _2284 = _2243 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2284 = _2277;\n        }\n        if (_2284)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2290 = _2233 > 3;\n        bool _2297;\n        if (_2290)\n        {\n            _2297 = _2243 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2297 = _2290;\n        }\n        if (_2297)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4469 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4469 = -_4469;\n    }\n    vec3 _3889 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n    Surface _3897 = fa_standard_surface(param_1);\n    vec3 _4500 = _3897.albedo;\n    float _4501 = _3897.alpha;\n    vec3 _4502 = _3897.normal;\n    float _4503 = _3897.metallic;\n    float _4504 = _3897.roughness;\n    float _4505 = _3897.occlusion;\n    vec3 _4506 = _3897.emission;\n    float _4507 = _3897.clearcoat;\n    float _4508 = _3897.clearcoat_roughness;\n    vec3 _4509 = _3897.sheen_color;\n    float _4510 = _3897.sheen_roughness;\n    float _4511 = _3897.anisotropy;\n    float _4512 = _3897.anisotropy_rotation;\n    float _4513 = _3897.specular;\n    float _4514 = _3897.ior;\n    vec3 _4515 = _3897.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n    Surface param_3 = _3897;\n    surface(param_2, param_3);\n    _4500 = param_3.albedo;\n    _4501 = param_3.alpha;\n    _4502 = param_3.normal;\n    _4503 = param_3.metallic;\n    _4504 = param_3.roughness;\n    _4505 = param_3.occlusion;\n    _4506 = param_3.emission;\n    _4507 = param_3.clearcoat;\n    _4508 = param_3.clearcoat_roughness;\n    _4509 = param_3.sheen_color;\n    _4510 = param_3.sheen_roughness;\n    _4511 = param_3.anisotropy;\n    _4512 = param_3.anisotropy_rotation;\n    _4513 = param_3.specular;\n    _4514 = param_3.ior;\n    _4515 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4469;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4500 = param_6;\n    _4502 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4500;\n    }\n    else\n    {\n        vec3 _3936 = normalize(_4502);\n        float _3943 = clamp(_4503, 0.0, 1.0);\n        float _3947 = clamp(_4504, 0.0500000007450580596923828125, 1.0);\n        float _3951 = _3947 * _3947;\n        float _3955 = _3951 * _3951;\n        float _3960 = max(dot(_3936, _3889), 9.9999997473787516355514526367188e-05);\n        vec3 _3966 = _4500 * (1.0 - _3943);\n        vec3 _3973 = mix(vec3(0.039999999105930328369140625), _4500, vec3(_3943));\n        vec3 f0 = _3973;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4469, fa_world_tangent, fa_uv, fa_vertex_color, _3889, gl_FrontFacing);\n        Surface param_9 = Surface(_4500, _4501, _4502, _4503, _4504, _4505, _4506, _4507, _4508, _4509, _4510, _4511, _4512, _4513, _4514, _4515);\n        vec3 param_10 = _3936;\n        vec3 param_11 = _3889;\n        float param_12 = _3943;\n        float param_13 = _3947;\n        vec3 param_14 = _3973;\n        FaLayers _3989 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _3936;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _3966) * _4505;\n        if (_3989.on)\n        {\n            lit *= _3989.base_scale;\n        }\n        int _4011 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4011; ln++)\n        {\n            int param_16 = ln;\n            int _4024 = fa_cl_light(param_16);\n            bool _4027 = fa_lm.z > 0.5;\n            bool _4033;\n            if (_4027)\n            {\n                int param_17 = _4024;\n                _4033 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4033 = _4027;\n            }\n            if (_4033)\n            {\n                continue;\n            }\n            int param_18 = _4024;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4469;\n            LightSample _4045 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4674 = _4045.direction;\n            float _4053 = max(dot(_3936, _4674), 0.0);\n            float _4059 = _4045.attenuation * _4045.shadow;\n            vec3 _4064 = normalize(_4674 + _3889);\n            float _4069 = max(dot(_3936, _4064), 0.0);\n            float _4074 = max(dot(_3889, _4064), 0.0);\n            if (_3989.on)\n            {\n                FaLayers param_21 = _3989;\n                vec3 param_22 = _3966;\n                vec3 param_23 = f0;\n                vec3 param_24 = _3936;\n                vec3 param_25 = _3889;\n                vec3 param_26 = _4674;\n                vec3 param_27 = _4064;\n                float param_28 = _4053;\n                float param_29 = _3960;\n                float param_30 = _4069;\n                float param_31 = _4074;\n                float param_32 = _3951;\n                float param_33 = _3955;\n                int param_34 = _4024;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4059));\n            }\n            else\n            {\n                float _4122 = ((_4069 * _4069) * (_3955 - 1.0)) + 1.0;\n                int param_35 = _4024;\n                lit += (((_3966 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4074, 5.0))) * (((_3955 / ((3.1415927410125732421875 * _4122) * _4122)) * (0.5 / max(mix((2.0 * _4053) * _3960, _4053 + _3960, _3951), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4053))) * fa_light_rgb(param_35)) * (_4053 * _4059));\n            }\n        }\n        if (_3989.on)\n        {\n            FaLayers param_36 = _3989;\n            vec3 param_37 = _3936;\n            vec3 param_38 = _3889;\n            vec3 param_39 = f0;\n            float param_40 = _3947;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4505);\n        }\n        else\n        {\n            vec3 param_41 = _3936;\n            vec3 param_42 = _3889;\n            vec3 param_43 = f0;\n            float param_44 = _3947;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4505);\n        }\n        result = lit;\n    }\n    vec3 _4215 = result;\n    vec3 _4216 = _4215 + _4506;\n    result = _4216;\n    vec3 param_45 = _4216;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4225 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4232;\n    if (!_4225)\n    {\n        _4232 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4232 = _4225;\n    }\n    if (_4232)\n    {\n        vec3 _4241 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4247 = dot(_4241, fa_mesh_fs_params[9].xyz);\n        bool _4251 = fa_mesh_fs_params[9].w > 0.5;\n        float _4252;\n        if (_4251)\n        {\n            _4252 = _4247;\n        }\n        else\n        {\n            _4252 = length(_4241);\n        }\n        float _4264 = _4252 - fa_mesh_fs_params[8].x;\n        if (_4264 > 0.0)\n        {\n            float _4273 = fa_mesh_fs_params[7].w * _4264;\n            float tau = _4273 * _4273;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4289;\n                if (_4251)\n                {\n                    _4289 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4247);\n                }\n                else\n                {\n                    _4289 = fa_mesh_fs_params[0].y;\n                }\n                float _4310 = mix(_4289, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4252, 0.0, 1.0));\n                float _4314 = fa_world_pos.y - _4310;\n                float _4319 = _4310 - fa_mesh_fs_params[8].z;\n                float _4324 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4327 = _4319 <= 0.0;\n                bool _4328 = !_4327;\n                bool _4334;\n                if (_4328)\n                {\n                    _4334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4334 = _4327;\n                }\n                float _4335;\n                if (_4334)\n                {\n                    _4335 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4335 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4319, 80.0));\n                }\n                bool _4362;\n                if (_4328)\n                {\n                    _4362 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4362 = _4327;\n                }\n                float _4363;\n                if (_4362)\n                {\n                    _4363 = fa_mesh_fs_params[8].y * _4319;\n                }\n                else\n                {\n                    _4363 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4319, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4388 = _4324 <= 0.0;\n                bool _4395;\n                if (!_4388)\n                {\n                    _4395 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4395 = _4388;\n                }\n                float _4396;\n                if (_4395)\n                {\n                    _4396 = fa_mesh_fs_params[8].y * _4324;\n                }\n                else\n                {\n                    _4396 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4324, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4423;\n                if (abs(_4314) < 0.001000000047497451305389404296875)\n                {\n                    _4423 = _4335;\n                }\n                else\n                {\n                    _4423 = (_4396 - _4363) / _4314;\n                }\n                tau += (_4264 * max(_4423, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4501);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_364",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_536",
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
            "inst_name": "_1276",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _217 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _224 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_217 * _224).z;\n    fa_pre_r0 = vec3(_217[0].x, _217[1].x, _217[2].x);\n    fa_pre_r1 = vec3(_217[0].y, _217[1].y, _217[2].y);\n    fa_pre_r2 = vec3(_217[0].z, _217[1].z, _217[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _224;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _754 = base_t;\n    _754.x = _242.x;\n    _754.y = _242.y;\n    _754.z = _242.z;\n    base_t = _754;\n    vec4 _257 = (_754 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _717 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _762 = _294;\n        _762.x = _299.x;\n        _762.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _765 = mrt;\n    _765.x = _328.x;\n    _765.y = _328.y;\n    _765.z = _328.z;\n    mrt = _765;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _722 = fa_mesh_fs_params[20].x;\n    float _723 = fa_mesh_fs_params[20].y;\n    float _726 = fa_mesh_fs_params[20].z;\n    float _725 = fa_mesh_fs_params[21].w;\n    float _728 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _722 *= _370.y;\n            _723 *= _370.z;\n            _725 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _717, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _722, _723, fa_mesh_fs_params[21].xyz, _725, _726, fa_mesh_fs_params[20].w, _728, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_182",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_286",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _329 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _336 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_329 * _336).z;\n    fa_pre_r0 = vec3(_329[0].x, _329[1].x, _329[2].x);\n    fa_pre_r1 = vec3(_329[0].y, _329[1].y, _329[2].y);\n    fa_pre_r2 = vec3(_329[0].z, _329[1].z, _329[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _336;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _754 = base_t;\n    _754.x = _242.x;\n    _754.y = _242.y;\n    _754.z = _242.z;\n    base_t = _754;\n    vec4 _257 = (_754 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _717 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _762 = _294;\n        _762.x = _299.x;\n        _762.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _762;\n        _717 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _765 = mrt;\n    _765.x = _328.x;\n    _765.y = _328.y;\n    _765.z = _328.z;\n    mrt = _765;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _722 = fa_mesh_fs_params[20].x;\n    float _723 = fa_mesh_fs_params[20].y;\n    float _726 = fa_mesh_fs_params[20].z;\n    float _725 = fa_mesh_fs_params[21].w;\n    float _728 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _722 *= _370.y;\n            _723 *= _370.z;\n            _725 *= _358.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _726 *= mrt.x;\n            _728 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _717, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _722, _723, fa_mesh_fs_params[21].xyz, _725, _726, fa_mesh_fs_params[20].w, _728, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _628 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _628 = -_628;\n    }\n    vec3 _534 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _628, fa_world_tangent, fa_uv, fa_vertex_color, _534, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _549 = normalize(param_2.normal);\n    vec3 _564 = normalize(vec3(dot(fa_pre_r0, _549), dot(fa_pre_r1, _549), dot(fa_pre_r2, _549)));\n    float _576 = _564.z;\n    vec2 e = _564.xy / vec2((abs(_564.x) + abs(_564.y)) + abs(_576));\n    if (_576 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_398",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _53 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _68;\n    if (!_53)\n    {\n        _68 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_173",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_213 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_213 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_213 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _58 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _73;\n    if (!_58)\n    {\n        _73 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_178",
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
            "inst_name": "_222",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_302",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    }
  }
}
