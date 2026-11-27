{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4936[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1607 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1614;\n    if (!_1607)\n    {\n        _1614 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1614 = _1607;\n    }\n    bool _1622;\n    if (!_1614)\n    {\n        _1622 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1622 = _1614;\n    }\n    bool _1629;\n    if (!_1622)\n    {\n        _1629 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1629 = _1622;\n    }\n    bool _1636;\n    if (!_1629)\n    {\n        _1636 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1636 = _1629;\n    }\n    if (_1636)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1646 = vec4(world_pos, 1.0);\n    float _1652 = dot(fa_mesh_fs_params[16], _1646);\n    if (!(_1652 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1674 = vec2(dot(fa_mesh_fs_params[14], _1646), dot(fa_mesh_fs_params[15], _1646)) / vec2(_1652);\n    int _1678 = int(fa_mesh_fs_params[18].x);\n    int _1682 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1682) + clamp(int(floor(((_1674.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1682 - 1)) * _1678)) + clamp(int(floor(((_1674.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1678 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1758 = fa_cluster_texel(param);\n    return ivec2(int(_1758.x), int(_1758.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6570 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6573 = fwidth(_6570);\n    bool _6576 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6583;\n    if (!_6576)\n    {\n        _6583 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6583 = _6576;\n    }\n    if (_6583)\n    {\n        fa_rt_slope = min(1.5 * _6573, 0.100000001490116119384765625 * _6570);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6599 = fa_cluster_lookup(param);\n    fa_cl_slot = _6599.x;\n    fa_cl_local = _6599.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7773 = fa_linear_to_srgb(param);\n        c = _7773;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7781 = fa_srgb_to_linear(param_1);\n            c = _7781;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _552;\n    if (i.front_facing)\n    {\n        _552 = i.world_normal;\n    }\n    else\n    {\n        _552 = -i.world_normal;\n    }\n    vec3 _576 = normalize(i.world_tangent.xyz - (_552 * dot(_552, i.world_tangent.xyz)));\n    vec3 _603 = normalize(((_576 * m.x) + ((cross(_552, _576) * i.world_tangent.w) * m.y)) + (_552 * m.z));\n    vec3 _606;\n    if (i.front_facing)\n    {\n        _606 = _603;\n    }\n    else\n    {\n        _606 = -_603;\n    }\n    return _606;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7813 = fa_tex_fix(param_2, param_3);\n    vec4 _10192 = base_t;\n    _10192.x = _7813.x;\n    _10192.y = _7813.y;\n    _10192.z = _7813.z;\n    base_t = _10192;\n    vec4 _7827 = (_10192 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9939 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7861 = fa_tex_fix(param_6, param_7);\n        vec3 _7864 = (_7861 * 2.0) - vec3(1.0);\n        vec2 _7869 = _7864.xy * fa_mesh_fs_params[6].x;\n        vec3 _10200 = _7864;\n        _10200.x = _7869.x;\n        _10200.y = _7869.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10200;\n        _9939 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7899 = fa_tex_fix(param_12, param_13);\n    vec4 _10203 = mrt;\n    _10203.x = _7899.x;\n    _10203.y = _7899.y;\n    _10203.z = _7899.z;\n    mrt = _10203;\n    vec4 _7929 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7929.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7940 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7972 = fa_tex_fix(param_20, param_21);\n    float _9944 = fa_mesh_fs_params[20].x;\n    float _9945 = fa_mesh_fs_params[20].y;\n    float _9948 = fa_mesh_fs_params[20].z;\n    float _9947 = fa_mesh_fs_params[21].w;\n    float _9950 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9944 *= _7940.y;\n            _9945 *= _7940.z;\n            _9947 *= _7929.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9948 *= mrt.x;\n            _9950 *= mrt.w;\n        }\n    }\n    return Surface(_7827.xyz, _7827.w, _9939, clamp(fa_mesh_fs_params[5].x * _7899.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7899.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7940.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7972), _9944, _9945, fa_mesh_fs_params[21].xyz, _9947, _9948, fa_mesh_fs_params[20].w, _9950, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1838 = rect.zw - rect.xy;\n    vec2 _1842 = _1838 * atlas;\n    vec2 _1846 = ddx * _1842;\n    vec2 _1850 = ddy * _1842;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1838), clamp(0.5 * log2(max(max(dot(_1846, _1846), dot(_1850, _1850)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1883 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1890;\n    if (!_1883)\n    {\n        _1890 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1890 = _1883;\n    }\n    if (_1890)\n    {\n        return;\n    }\n    vec3 _1896 = dFdx(world_pos);\n    vec3 _1899 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1903 = fa_cluster_texel(param);\n    int _1907 = int(_1903.w);\n    if (_1907 < 1)\n    {\n        return;\n    }\n    int _1917 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1917;\n    vec4 _1921 = fa_light_texel(param_1);\n    vec2 _1924 = _1921.yz;\n    int _1928 = int(_1921.w);\n    int param_2 = _1917 + 1;\n    vec4 _1933 = fa_light_texel(param_2);\n    float _1934 = _1933.x;\n    int _1940 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1944 = int(_1903.z);\n    vec3 _2209;\n    for (int k = 0; k < _1907; k++)\n    {\n        int _1957 = _1944 + k;\n        int param_3 = _1928 + (_1957 >> 2);\n        int _1974 = (_1917 + 2) + (int(fa_light_texel(param_3)[_1957 & 3]) * 7);\n        int param_4 = _1974 + 6;\n        vec4 _1979 = fa_light_texel(param_4);\n        if (((int(_1979.w + 0.5) >> _1940) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1974;\n        vec4 _1994 = fa_light_texel(param_5);\n        int param_6 = _1974 + 1;\n        vec4 _1999 = fa_light_texel(param_6);\n        int param_7 = _1974 + 2;\n        vec4 _2004 = fa_light_texel(param_7);\n        vec3 _2007 = _1994.xyz;\n        float _2012 = dot(_2007, world_pos) + _1994.w;\n        vec3 _2014 = _1999.xyz;\n        float _2019 = dot(_2014, world_pos) + _1999.w;\n        vec3 _2021 = _2004.xyz;\n        float _2026 = dot(_2021, world_pos) + _2004.w;\n        bool _2031 = abs(_2012) > 0.5;\n        bool _2039;\n        if (!_2031)\n        {\n            _2039 = abs(_2019) > 0.5;\n        }\n        else\n        {\n            _2039 = _2031;\n        }\n        bool _2047;\n        if (!_2039)\n        {\n            _2047 = abs(_2026) > 0.5;\n        }\n        else\n        {\n            _2047 = _2039;\n        }\n        if (_2047)\n        {\n            continue;\n        }\n        float _2062 = clamp(dot(geo_normal, normalize(_2021)) * _1979.z, 0.0, 1.0);\n        if (_2062 <= 0.0)\n        {\n            continue;\n        }\n        float _2082 = (clamp((0.5 - abs(_2026)) * 10.0, 0.0, 1.0) * _2062) * _1979.x;\n        vec2 _2090 = vec2(_2012 + 0.5, 0.5 - _2019);\n        vec2 _2100 = vec2(dot(_2007, _1896), dot(_2014, _1896));\n        vec2 _2110 = vec2(dot(_2007, _1899), dot(_2014, _1899));\n        int param_8 = _1974 + 5;\n        vec4 _2115 = fa_light_texel(param_8);\n        int param_9 = _1974 + 3;\n        vec4 _2120 = fa_light_texel(param_9);\n        int param_10 = _1974 + 4;\n        vec4 _2125 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2115.xyz;\n        bool _2135 = _2120.z > _2120.x;\n        if (_2135)\n        {\n            vec4 param_11 = _2120;\n            vec2 param_12 = _2090;\n            vec2 param_13 = _1924;\n            vec2 param_14 = _2100;\n            vec2 param_15 = _2110;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1934 > 0.5) && (_1934 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2161 = fa_dc_to_linear(param_16);\n                vec4 _10027 = tx;\n                _10027.x = _2161.x;\n                _10027.y = _2161.y;\n                _10027.z = _2161.z;\n                tx = _10027;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2082 * tex_a) * _2115.w, 0.0, 1.0)));\n        if (_2125.z > _2125.x)\n        {\n            vec4 param_17 = _2125;\n            vec2 param_18 = _2090;\n            vec2 param_19 = _1924;\n            vec2 param_20 = _2100;\n            vec2 param_21 = _2110;\n            vec4 _2205 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1934 > 1.5)\n            {\n                vec3 param_22 = _2205.xyz;\n                vec3 _2215 = fa_dc_to_srgb(param_22);\n                _2209 = _2215;\n            }\n            else\n            {\n                _2209 = _2205.xyz;\n            }\n            vec3 _2224 = (_2209 * 2.0) - vec3(1.0);\n            vec2 _2229 = _2224.xy * _1979.y;\n            vec3 _2251 = (normalize(_2007) * _2229.x) + (normalize(_2014) * _2229.y);\n            vec3 _2254 = normalize(normal);\n            normal = normalize(mix(_2254, normalize((_2254 * max(_2224.z, 0.0500000007450580596923828125)) + (_2251 - (_2254 * dot(_2254, _2251)))), vec3(clamp(_2082 * (_2135 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4861 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4869 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4872 = int(_4861);\n    int _4875 = int(_4869);\n    float _4885 = _4869 - float(_4875);\n    int _4940 = (_4872 * 9) + _4875;\n    int _4960 = ((_4872 + 1) * 9) + _4875;\n    return mix(mix(_4936[_4940], _4936[_4940 + 1], _4885), mix(_4936[_4960], _4936[_4960 + 1], _4885), _4861 - float(_4872));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9862 = false;\n    float _9863 = 1.0;\n    float _9864 = 1.0;\n    float _9865 = 1.0;\n    float _9866 = 0.0;\n    float _9867 = 0.0;\n    float _9868 = 0.0;\n    float _9869 = 0.0;\n    float _9871 = 1.0;\n    bool _9872 = false;\n    vec3 _9873 = vec3(0.0);\n    float _9874 = 1.0;\n    float _9875 = 1.0;\n    float _9876 = 1.0;\n    float _9877 = 0.0;\n    float _9878 = 0.0;\n    vec3 _9879 = vec3(1.0, 0.0, 0.0);\n    vec3 _9880 = vec3(0.0, 0.0, 1.0);\n    float _9881 = 1.0;\n    float _9882 = 1.0;\n    float _5011 = clamp(s.specular, 0.0, 1.0);\n    float _5015 = clamp(s.ior, 1.0, 3.0);\n    bool _5020 = (_5011 != 1.0) || (_5015 != 1.5);\n    bool _5029;\n    if (!_5020)\n    {\n        _5029 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5029 = _5020;\n    }\n    if (_5029)\n    {\n        float _5037 = (_5015 - 1.0) / (_5015 + 1.0);\n        f0 = mix(min(vec3(_5037 * _5037) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5011, s.albedo, vec3(metallic));\n        _9863 = mix(_5011, 1.0, metallic);\n        _9862 = true;\n    }\n    float _5064 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5064 > 0.0)\n    {\n        float _5072 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9866 = _5064;\n        _9867 = _5072;\n        float _5079 = _5072 * _5072;\n        _9868 = _5079;\n        _9869 = _5079 * _5079;\n        float _5091 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9871 = _5091;\n        _9864 = 1.0 - (_5064 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5091, 0.0, 1.0), 5.0))));\n        _9862 = true;\n    }\n    vec3 _5110 = max(s.sheen_color, vec3(0.0));\n    float _5119 = max(_5110.x, max(_5110.y, _5110.z));\n    if (_5119 > 0.0)\n    {\n        float _5127 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9872 = true;\n        _9873 = _5110;\n        _9874 = _5127;\n        _9875 = _5127 * _5127;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5127;\n        float _5144 = fa_sheen_albedo(param, param_1);\n        _9877 = _5144;\n        _9876 = 1.0 - min(_5119 * _5144, 1.0);\n        _9862 = true;\n    }\n    _9865 = _9864 * _9876;\n    float _5163 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5163 != 0.0)\n    {\n        vec3 _5178 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5178;\n        if (dot(_5178, _5178) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5190 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5190.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5190.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5190.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5194 = t;\n        vec3 _5195 = normalize(_5194);\n        t = _5195;\n        vec3 _5220 = normalize((_5195 * cos(s.anisotropy_rotation)) + ((cross(n, _5195) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9879 = _5220;\n        _9880 = cross(n, _5220);\n        float _5230 = roughness * roughness;\n        float _5236 = mix(_5230, 1.0, _5163 * _5163);\n        bool _5238 = _5163 > 0.0;\n        _9881 = _5238 ? _5236 : _5230;\n        _9882 = _5238 ? _5230 : _5236;\n        _9878 = _5163;\n        _9862 = true;\n    }\n    return FaLayers(_9862, _9863, _9864, _9865, _9866, _9867, _9868, _9869, i.world_normal, _9871, _9872, _9873, _9874, _9875, _9876, _9877, _9878, _9879, _9880, _9881, _9882);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4031 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4031;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4642 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4647 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4642 > 0.0005000000237487256526947021484375)\n    {\n        if (_4647)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4642;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4642;\n        }\n    }\n    bool _4698 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4698)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4729 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4729)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4647 || _4698) || _4729)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4051 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4054 = _4051.x;\n    float _4056 = _4051.z;\n    vec2 e = vec2(_4054, _4056);\n    if (_4051.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4056)) * ((_4054 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4054)) * ((_4056 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8082 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8087 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8092 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8097 = fa_light_texel(param_3);\n    bool _8100 = _8097.z < 0.5;\n    bool _8108;\n    if (!_8100)\n    {\n        _8108 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8108 = _8100;\n    }\n    if (_8108)\n    {\n        return vec3(0.0);\n    }\n    float _8115 = max(_8082.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8118 = _8087.xyz;\n    vec3 _8122 = _8082.xyz;\n    vec3 _8126 = (fa_world_pos - _8122) / vec3(_8115);\n    vec3 _8135 = min(_8126 + vec3(0.5), (_8118 - vec3(0.5)) - _8126);\n    float _8144 = min(_8135.x, min(_8135.y, _8135.z));\n    if (!(_8144 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8159 = _8118 - vec3(1.0);\n    vec3 _8160 = clamp(_8126, vec3(0.0), _8159);\n    vec3 _8168 = min(floor(_8160), max(_8118 - vec3(2.0), vec3(0.0)));\n    vec3 _8172 = _8160 - _8168;\n    vec3 _8183 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8115));\n    int _8188 = int(_8092.y + 0.5);\n    float _8193 = 0.3257350027561187744140625 * n.y;\n    float _8197 = 0.3257350027561187744140625 * n.z;\n    float _8201 = 0.3257350027561187744140625 * n.x;\n    float _8208 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8215 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8224 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8231 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8244 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8251 = 8 + int(_8097.w);\n    float _8278;\n    float _8291;\n    float _8305;\n    for (int k = 0; k < _8251; k++)\n    {\n        float _8264 = float(k & 1);\n        float _8268 = float((k >> 1) & 1);\n        float _8272 = float((k >> 2) & 1);\n        if (_8264 > 0.5)\n        {\n            _8278 = _8172.x;\n        }\n        else\n        {\n            _8278 = 1.0 - _8172.x;\n        }\n        if (_8268 > 0.5)\n        {\n            _8291 = _8172.y;\n        }\n        else\n        {\n            _8291 = 1.0 - _8172.y;\n        }\n        if (_8272 > 0.5)\n        {\n            _8305 = _8172.z;\n        }\n        else\n        {\n            _8305 = 1.0 - _8172.z;\n        }\n        float _8315 = (_8278 * _8291) * _8305;\n        if (!(_8315 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8328 = min(_8168 + vec3(_8264, _8268, _8272), _8159);\n        int _8348 = int(((_8092.x + _8328.x) + (_8087.x * (_8328.y + (_8087.y * _8328.z)))) + 0.5);\n        vec2 _8363 = vec2(float(_8348 % _8188) * 10.0, 1024.0 + (float(_8348 / _8188) * 11.0));\n        vec2 param_4 = _8363 + vec2(9.5, 10.5);\n        vec4 _8371 = fa_gi_fetch(param_4);\n        bool _8374 = _8371.y < 0.5;\n        bool _8383;\n        if (!_8374)\n        {\n            _8383 = _8371.x > _8097.y;\n        }\n        else\n        {\n            _8383 = _8374;\n        }\n        if (_8383)\n        {\n            continue;\n        }\n        vec3 _8395 = _8183 - (_8122 + (_8328 * _8115));\n        float _8398 = length(_8395);\n        vec3 _8404 = _8395 / vec3(max(_8398, 9.9999997473787516355514526367188e-05));\n        float _8414 = max(9.9999997473787516355514526367188e-05, (dot(-_8404, n) + 1.0) * 0.5);\n        float w = _8315 * (_8414 * _8414);\n        vec3 param_5 = _8404;\n        vec2 param_6 = (_8363 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8433 = fa_gi_fetch(param_6);\n        float _8440 = _8398 / max(_8092.z, 9.9999997473787516355514526367188e-05);\n        float _8443 = _8433.x;\n        if (_8440 > _8443)\n        {\n            float _8456 = max(_8433.y - (_8443 * _8443), 0.0);\n            float _8461 = _8440 - _8443;\n            float _8470 = _8456 / max(_8456 + (_8461 * _8461), 9.9999999600419720025001879548654e-13);\n            w *= ((_8470 * _8470) * _8470);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8363 + vec2(0.5, 10.5);\n        vec2 param_8 = _8363 + vec2(1.5, 10.5);\n        vec2 param_9 = _8363 + vec2(2.5, 10.5);\n        vec2 param_10 = _8363 + vec2(3.5, 10.5);\n        vec2 param_11 = _8363 + vec2(4.5, 10.5);\n        vec2 param_12 = _8363 + vec2(5.5, 10.5);\n        vec2 param_13 = _8363 + vec2(6.5, 10.5);\n        vec2 param_14 = _8363 + vec2(7.5, 10.5);\n        vec2 param_15 = _8363 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8193)) + (fa_gi_fetch(param_9).xyz * _8197)) + (fa_gi_fetch(param_10).xyz * _8201)) + (fa_gi_fetch(param_11).xyz * _8208)) + (fa_gi_fetch(param_12).xyz * _8215)) + (fa_gi_fetch(param_13).xyz * _8224)) + (fa_gi_fetch(param_14).xyz * _8231)) + (fa_gi_fetch(param_15).xyz * _8244)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8144 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8595;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8595 = _8097.x;\n    }\n    else\n    {\n        _8595 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8092.w * _8595);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8619 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8624 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8629 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8629) && (k < 8); k++)\n    {\n        int param = _8624 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8619;\n        vec3 _8654 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8659 = param_3 * left;\n        acc += (_8654 * _8659);\n        left -= _8659;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8688 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8688;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8730 = vec4(fa_world_pos, 1.0);\n        vec2 _8749 = vec2(dot(fa_mesh_fs_params[26], _8730), dot(fa_mesh_fs_params[27], _8730)) / vec2(max(dot(fa_mesh_fs_params[28], _8730), 9.9999997473787516355514526367188e-05));\n        float _8758;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8758 = (_8749.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8758 = 0.5 - (_8749.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8749.x * 0.5) + 0.5, _8758) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6540;\n    if (fa_lm.z > 0.5)\n    {\n        _6540 = 0.0;\n    }\n    else\n    {\n        _6540 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6551 = _6540 < 1.0;\n    bool _6557;\n    if (_6551)\n    {\n        int param = li;\n        _6557 = fa_light_baked(param);\n    }\n    else\n    {\n        _6557 = _6551;\n    }\n    return _6557 ? _6540 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _856 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _869 = (c - (ru * hx)) - p;\n        vec3 _875 = ru * (2.0 * hx);\n        float _881 = max(dot(_875, _875), 9.9999999392252902907785028219223e-09);\n        float _885 = dot(_869, _875);\n        float t = clamp((-_885) / _881, 0.0, 1.0);\n        if (_856)\n        {\n            float _900 = dot(r, _875);\n            float _906 = _881 - (_900 * _900);\n            if (abs(_906) > (9.9999997473787516355514526367188e-06 * _881))\n            {\n                t = clamp(((dot(r, _869) * _900) - _885) / _906, 0.0, 1.0);\n            }\n        }\n        return (p + _869) + (_875 * t);\n    }\n    vec3 q = p;\n    float _938 = dot(r, axis);\n    bool _946;\n    if (_856)\n    {\n        _946 = abs(_938) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _946 = _856;\n    }\n    if (_946)\n    {\n        float _956 = dot(c - p, axis) / _938;\n        if (_956 > 0.0)\n        {\n            q = p + (r * _956);\n        }\n    }\n    vec3 _969 = q - c;\n    vec2 xy = vec2(dot(_969, ru), dot(_969, uu));\n    if (shape > 0.5)\n    {\n        float _984 = length(xy);\n        if (_984 > hx)\n        {\n            xy *= (hx / _984);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _618 = abs(d);\n    float _620 = _618.x;\n    float _622 = _618.y;\n    bool _623 = _620 >= _622;\n    bool _631;\n    if (_623)\n    {\n        _631 = _620 >= _618.z;\n    }\n    else\n    {\n        _631 = _623;\n    }\n    int _632;\n    if (_631)\n    {\n        _632 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _646;\n        if (_622 >= _618.z)\n        {\n            _646 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _646 = (d.z > 0.0) ? 4 : 5;\n        }\n        _632 = _646;\n    }\n    return _632;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _776 = dot(d, right);\n    float _780 = dot(d, up);\n    float _791;\n    if (((_776 * _776) + (_780 * _780)) > 1.0000000133514319600180897396058e-10)\n    {\n        _791 = atan(_780, _776) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _791 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_791 - floor(_791)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1022 = fa_light_base(param);\n    bool _1026 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1022;\n    vec4 _1030 = fa_light_texel(param_1);\n    int param_2 = _1022 + 1;\n    vec4 _1035 = fa_light_texel(param_2);\n    float _1038 = _1035.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1050 = _1026 && (_1038 > 2.5);\n    fa_light_is_area = _1050;\n    bool _1052 = _1038 < 0.5;\n    vec3 l;\n    if (_1052)\n    {\n        l = normalize(_1030.xyz);\n        if (_1026)\n        {\n            int param_3 = _1022 + 6;\n            vec4 _1066 = fa_light_texel(param_3);\n            if (_1066.z > 0.5)\n            {\n                int param_4 = _1022 + 4;\n                vec4 _1076 = fa_light_texel(param_4);\n                int param_5 = _1022 + 5;\n                vec4 _1081 = fa_light_texel(param_5);\n                vec2 param_6 = _1066.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1076.xyz) * _1076.w, (-dot(world_pos, _1081.xyz)) * _1081.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1111 = _1030.xyz;\n        vec3 _1113 = _1111 - world_pos;\n        vec3 to_light = _1113;\n        float _1116 = length(_1113);\n        float reach = _1116;\n        bool front = true;\n        if (_1050)\n        {\n            int param_8 = _1022 + 7;\n            reach = max(_1116 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1022 + 4;\n            vec4 _1140 = fa_light_texel(param_9);\n            int param_10 = _1022 + 5;\n            vec4 _1145 = fa_light_texel(param_10);\n            int param_11 = _1022 + 6;\n            vec4 _1150 = fa_light_texel(param_11);\n            float _1151 = _1150.w;\n            int param_12 = _1022 + 2;\n            vec3 _1158 = normalize(fa_light_texel(param_12).xyz);\n            bool _1160 = _1151 > 1.5;\n            bool _1168;\n            if (!_1160)\n            {\n                _1168 = dot(_1158, to_light) < 0.0;\n            }\n            else\n            {\n                _1168 = _1160;\n            }\n            front = _1168;\n            vec3 r = vec3(0.0);\n            vec3 _1177 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1181 = dot(n, n) > 0.5;\n            bool _1189;\n            if (_1181)\n            {\n                _1189 = dot(_1177, _1177) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            if (_1189)\n            {\n                r = reflect(-normalize(_1177), normalize(n));\n            }\n            vec3 param_13 = _1111;\n            vec3 param_14 = _1158;\n            vec3 param_15 = _1140.xyz;\n            vec3 param_16 = _1145.xyz;\n            float param_17 = _1140.w;\n            float param_18 = _1145.w;\n            float param_19 = _1151;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1225 = length(to_light);\n        dist = _1225;\n        l = to_light / vec3(max(_1225, 9.9999997473787516355514526367188e-05));\n        float _1239 = reach / max(_1030.w, 0.001000000047497451305389404296875);\n        float _1245 = clamp(1.0 - (_1239 * _1239), 0.0, 1.0);\n        float _1247;\n        if (front)\n        {\n            _1247 = _1245 * _1245;\n        }\n        else\n        {\n            _1247 = 0.0;\n        }\n        atten = _1247;\n        bool _1258 = _1038 < 2.5;\n        if ((_1038 > 1.5) && _1258)\n        {\n            int param_22 = _1022 + 2;\n            vec4 _1266 = fa_light_texel(param_22);\n            float _1276 = _1266.w;\n            int param_23 = _1022 + 3;\n            vec4 _1281 = fa_light_texel(param_23);\n            float _1282 = _1281.x;\n            float cos_inner = _1282;\n            if (_1282 > 1.5)\n            {\n                cos_inner = mix(_1276, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1276, cos_inner, dot(-l, normalize(_1266.xyz)));\n        }\n        if (_1026 && (_1038 < 1.5))\n        {\n            int param_24 = _1022 + 6;\n            vec4 _1306 = fa_light_texel(param_24);\n            if (_1306.z > 0.5)\n            {\n                vec3 _1314 = -to_light;\n                int param_25 = _1022 + 4;\n                int param_26 = _1022 + 5;\n                vec3 _1328 = fa_light_texel(param_25).xyz;\n                vec3 _1332 = fa_light_texel(param_26).xyz;\n                vec3 _1341 = vec3(dot(_1314, _1328), dot(_1314, _1332), dot(_1314, cross(_1328, _1332)));\n                vec3 param_27 = _1341;\n                int _1345 = fa_cube_face(param_27);\n                int param_28 = _1345;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1372 = vec2(dot(_1341, cross(param_29, param_30)), dot(_1341, param_30)) / vec2(max(dot(_1341, param_29), 9.9999997473787516355514526367188e-05));\n                int _1376 = _1345 / 3;\n                vec2 param_31 = _1306.xy + (vec2(float(_1345 - (_1376 * 3)), float(_1376)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1372.x), 0.5 - (0.5 * _1372.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1022 + 7;\n            vec4 _1406 = fa_light_texel(param_33);\n            if (_1406.z > 0.5)\n            {\n                int param_34 = _1022 + 2;\n                int param_35 = _1022 + 4;\n                int param_36 = _1022 + 5;\n                vec2 param_37 = _1406.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1026 && _1258)\n            {\n                int param_42 = _1022 + 6;\n                vec4 _1453 = fa_light_texel(param_42);\n                int param_43 = _1022 + 7;\n                vec4 _1458 = fa_light_texel(param_43);\n                bool _1461 = _1453.z > 0.5;\n                bool _1468;\n                if (!_1461)\n                {\n                    _1468 = _1458.z > 0.5;\n                }\n                else\n                {\n                    _1468 = _1461;\n                }\n                if (_1468)\n                {\n                    int param_44 = _1022 + 2;\n                    vec4 _1475 = fa_light_texel(param_44);\n                    vec3 _1479 = normalize(_1475.xyz);\n                    int param_45 = _1022 + 4;\n                    vec4 _1484 = fa_light_texel(param_45);\n                    int param_46 = _1022 + 5;\n                    vec4 _1489 = fa_light_texel(param_46);\n                    if (_1461)\n                    {\n                        vec3 _1497 = -to_light;\n                        float _1504 = _1475.w;\n                        float _1520 = 0.5 / max(dot(_1497, _1479) * (sqrt(max(1.0 - (_1504 * _1504), 0.0)) / max(_1504, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1453.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1497, _1484.xyz) * _1520), 0.5 - (dot(_1497, _1489.xyz) * _1520));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1458.z > 0.5)\n                    {\n                        vec2 param_49 = _1458.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1479;\n                        vec3 param_52 = _1484.xyz;\n                        vec3 param_53 = _1489.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9850 = _1035.xyz * atten;\n    if (_1026)\n    {\n        _9850 *= fa_light_tint;\n    }\n    int _1589;\n    if (_1052)\n    {\n        _1589 = 0;\n    }\n    else\n    {\n        _1589 = ((_1038 > 1.5) && (_1038 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9850, atten, 1.0, dist, _1589);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2321;\n    if (i == 0)\n    {\n        _2321 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2337;\n        if (i == 1)\n        {\n            _2337 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2345;\n            if (i == 2)\n            {\n                _2345 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2345 = fa_shadows[24].w;\n            }\n            _2337 = _2345;\n        }\n        _2321 = _2337;\n    }\n    return _2321;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2378 = fa_shadow_depth(param, param_1);\n    float _2382;\n    if (conv.x < 0.5)\n    {\n        _2382 = _2378;\n    }\n    else\n    {\n        _2382 = (conv.y * conv.z) / (conv.z - (_2378 * (conv.z - conv.y)));\n    }\n    return _2382;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2428 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2434 = vec2(cos(_2428), sin(_2428));\n    vec2 dir = _2434;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2443;\n        if (k < 0.0)\n        {\n            _2443 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2443 = k;\n        }\n        float _2462 = clamp((_2443 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2481 = sqrt((float(i) + 0.5) * 0.0625) * _2462;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2481));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2495 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2495 < (zr - (_2481 * plane)))\n            {\n                sum += _2495;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2523 = sum / cnt;\n        float _2533;\n        if (k < 0.0)\n        {\n            _2533 = (-k) / max(_2523, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2533 = k;\n        }\n        radius = clamp(((max(zr - _2523, 0.0) * unit) * _2533) / texel_m, 1.5, 16.0);\n        dir = _2434;\n    }\n    float lit = 0.0;\n    int _2559 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2559; i_1++)\n    {\n        float _2578 = sqrt((float(i_1) + 0.5) / float(_2559)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2578));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2578 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2559);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2624 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2629 = clamp(dot(n, l), 0.0, 1.0);\n    float _2635 = sqrt(1.0 - (_2629 * _2629));\n    float _2643 = min(_2635 / max(_2629, 0.20000000298023223876953125), 4.0);\n    float _2648;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2648 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2648 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2673 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2648 * _2635)), 1.0);\n    float _2680 = _2673.x;\n    bool _2683 = _2680 < fa_shadows[ci * 1 + 16].x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2673.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2673.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2717;\n    if (!_2710)\n    {\n        _2717 = _2673.z > 1.0;\n    }\n    else\n    {\n        _2717 = _2710;\n    }\n    if (_2717)\n    {\n        return -1.0;\n    }\n    float _2725;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2725 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2725 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2673.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2673.z - ((_2725 * (1.0 + (0.5 * _2643))) / _2624);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2624;\n    float param_5 = _2624 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2643, 3.0)) * 0.5) / _2624;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3103 = int(fa_shadows[25].x + 0.5);\n    if (_3103 < 1)\n    {\n        return 1.0;\n    }\n    float _3118 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3103 - 1;\n    if (_3118 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3130 = _3103 > 1;\n    bool _3137;\n    if (_3130)\n    {\n        _3137 = _3118 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3137 = _3130;\n    }\n    if (_3137)\n    {\n        ci = 1;\n    }\n    bool _3141 = _3103 > 2;\n    bool _3148;\n    if (_3141)\n    {\n        _3148 = _3118 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3148 = _3141;\n    }\n    if (_3148)\n    {\n        ci = 2;\n    }\n    bool _3152 = _3103 > 3;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3118 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3170 = min(_3103, 4);\n    float _3211;\n    for (int c = ci; c < _3170; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3190 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3190;\n            break;\n        }\n        if (_3190 < 0.0)\n        {\n            continue;\n        }\n        s = _3190;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3211 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3211 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3230 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3211, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3118 - (fa_shadow_split_at(param_7) - _3230)) / _3230, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3262;\n        if ((ci + 1) < _3103)\n        {\n            _3262 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3262 = 1.0;\n        }\n        s = mix(s, _3262, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3367 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3373;\n    if (_3367)\n    {\n        _3373 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3373 = _3367;\n    }\n    if (_3373)\n    {\n        float _3387 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3395 = vec4(fa_world_pos, 1.0);\n        float _3401 = dot(fa_mesh_fs_params[28], _3395);\n        if (_3401 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3420 = vec2(dot(fa_mesh_fs_params[26], _3395), dot(fa_mesh_fs_params[27], _3395)) / vec2(_3401);\n            float _3425 = (_3420.x * 0.5) + 0.5;\n            float _3429;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3429 = (_3420.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3429 = 0.5 - (_3420.y * 0.5);\n            }\n            bool _3445 = _3425 >= 0.0;\n            bool _3451;\n            if (_3445)\n            {\n                _3451 = _3425 < 1.0;\n            }\n            else\n            {\n                _3451 = _3445;\n            }\n            bool _3457;\n            if (_3451)\n            {\n                _3457 = _3429 >= 0.0;\n            }\n            else\n            {\n                _3457 = _3451;\n            }\n            bool _3463;\n            if (_3457)\n            {\n                _3463 = _3429 < 1.0;\n            }\n            else\n            {\n                _3463 = _3457;\n            }\n            if (_3463)\n            {\n                vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3425, _3429) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3491 = _3488.w > 0.5;\n                bool _3507;\n                if (_3491)\n                {\n                    _3507 = abs(_3387 - _3488.x) <= (((0.00200000009499490261077880859375 * _3387) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3507 = _3491;\n                }\n                if (_3507)\n                {\n                    float _3513;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3513 = min(_3488.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3513 = _3488.y;\n                    }\n                    return _3513;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3550 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3553 = _3550.w > 0.5;\n    bool _3563;\n    if (_3553)\n    {\n        _3563 = abs(d - _3550.x) <= tol;\n    }\n    else\n    {\n        _3563 = _3553;\n    }\n    if (_3563)\n    {\n        best = min(best, mod(floor(_3550.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2783 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2790;\n    if (!_2783)\n    {\n        _2790 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2790 = _2783;\n    }\n    if (_2790)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2803 = fa_light_texel(param);\n    float _2804 = _2803.x;\n    if (_2804 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2813 = int(_2804 + 0.5);\n    int param_1 = _2813;\n    vec4 _2817 = fa_light_texel(param_1);\n    int param_2 = _2813 + 1;\n    vec4 _2822 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2825 = _2817.y;\n    if (_2825 > 0.0)\n    {\n        float _2842 = 1.0 - smoothstep(0.75 * _2825, _2825, length(world - fa_shadows[27].xyz));\n        fade = _2842;\n        if (_2842 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2817.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2866 = (_2813 + 2) + (face * 6);\n    int param_4 = _2866;\n    int param_5 = _2866 + 1;\n    int param_6 = _2866 + 3;\n    vec4 _2880 = fa_light_texel(param_6);\n    int param_7 = _2866 + 4;\n    vec4 _2885 = fa_light_texel(param_7);\n    int param_8 = _2866 + 5;\n    vec4 _2890 = fa_light_texel(param_8);\n    float _2902 = _2890.x * max(dot(_2880, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2907 = clamp(dot(n, l), 0.0, 1.0);\n    float _2930 = clamp(dot(n, _2880.xyz), -1.0, 1.0);\n    float _2949 = min(sqrt(1.0 - (_2930 * _2930)) / max(abs(dot(n, world - lpos)) / max(dot(_2880, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2952 = _2822.y;\n    float _2954;\n    if (_2952 > 0.0)\n    {\n        _2954 = _2952;\n    }\n    else\n    {\n        _2954 = 1.5 * _2902;\n    }\n    vec4 _2974 = vec4(world + (n * (_2954 * sqrt(1.0 - (_2907 * _2907)))), 1.0);\n    float _2978 = dot(_2880, _2974);\n    float _2981 = _2890.y;\n    if (_2978 < _2981)\n    {\n        return 1.0;\n    }\n    vec2 _2996 = vec2(dot(fa_light_texel(param_4), _2974), dot(fa_light_texel(param_5), _2974)) / vec2(_2978);\n    float _2998 = _2996.x;\n    bool _3001 = _2998 < _2885.x;\n    bool _3010;\n    if (!_3001)\n    {\n        _3010 = _2998 > _2885.z;\n    }\n    else\n    {\n        _3010 = _3001;\n    }\n    bool _3019;\n    if (!_3010)\n    {\n        _3019 = _2996.y < _2885.y;\n    }\n    else\n    {\n        _3019 = _3010;\n    }\n    bool _3028;\n    if (!_3019)\n    {\n        _3028 = _2996.y > _2885.w;\n    }\n    else\n    {\n        _3028 = _3019;\n    }\n    if (_3028)\n    {\n        return 1.0;\n    }\n    float _3034 = _2822.x;\n    float _3036;\n    if (_3034 > 0.0)\n    {\n        _3036 = _3034;\n    }\n    else\n    {\n        _3036 = 1.5 * _2902;\n    }\n    vec2 param_9 = _2996;\n    vec4 param_10 = _2885;\n    float param_11 = _2978 - (_3036 * (1.0 + (0.5 * _2949)));\n    float param_12 = _2902;\n    float param_13 = 1.0;\n    float param_14 = _2890.z * 0.25;\n    float param_15 = (_2902 * min(_2949, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2981, _2890.z);\n    int param_17 = int(_2817.z + 0.5);\n    float param_18 = _2817.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3581 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3587;\n    if (_3581)\n    {\n        _3587 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3587 = _3581;\n    }\n    bool _3593;\n    if (_3587)\n    {\n        _3593 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3593 = _3587;\n    }\n    if (_3593)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3605 = fa_light_texel(param);\n        float _3606 = _3605.z;\n        if (_3606 > 0.5)\n        {\n            float _3619 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3625 = ((0.00200000009499490261077880859375 * _3619) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3631 = vec4(world, 1.0);\n            float _3636 = dot(fa_mesh_fs_params[28], _3631);\n            if (_3636 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3653 = vec2(dot(fa_mesh_fs_params[26], _3631), dot(fa_mesh_fs_params[27], _3631)) / vec2(_3636);\n                float _3658 = (_3653.x * 0.5) + 0.5;\n                float _3662;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3662 = (_3653.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3662 = 0.5 - (_3653.y * 0.5);\n                }\n                bool _3678 = _3658 >= 0.0;\n                bool _3684;\n                if (_3678)\n                {\n                    _3684 = _3658 < 1.0;\n                }\n                else\n                {\n                    _3684 = _3678;\n                }\n                bool _3690;\n                if (_3684)\n                {\n                    _3690 = _3662 >= 0.0;\n                }\n                else\n                {\n                    _3690 = _3684;\n                }\n                bool _3696;\n                if (_3690)\n                {\n                    _3696 = _3662 < 1.0;\n                }\n                else\n                {\n                    _3696 = _3690;\n                }\n                if (_3696)\n                {\n                    ivec2 _3703 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3714 = clamp(ivec2(vec2(_3658, _3662) * fa_mesh_fs_params[24].zw), ivec2(0), _3703 - ivec2(1));\n                    float _3718;\n                    if (_3606 < 1.5)\n                    {\n                        _3718 = 1.0;\n                    }\n                    else\n                    {\n                        _3718 = (_3606 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3734 = texelFetch(fa_screen_tex_fa_shadow_smp, _3714, 0);\n                    bool _3737 = _3734.w > 0.5;\n                    bool _3747;\n                    if (_3737)\n                    {\n                        _3747 = abs(_3619 - _3734.x) <= _3625;\n                    }\n                    else\n                    {\n                        _3747 = _3737;\n                    }\n                    if (_3747)\n                    {\n                        best = mod(floor(_3734.z / _3718), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3714 + ivec2(-1);\n                        ivec2 param_2 = _3703;\n                        float param_3 = _3619;\n                        float param_4 = _3625;\n                        float param_5 = _3718;\n                        float param_6 = best;\n                        float _3773 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3773;\n                        ivec2 param_7 = _3714 + ivec2(0, -1);\n                        ivec2 param_8 = _3703;\n                        float param_9 = _3619;\n                        float param_10 = _3625;\n                        float param_11 = _3718;\n                        float param_12 = _3773;\n                        float _3788 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3788;\n                        ivec2 param_13 = _3714 + ivec2(1, -1);\n                        ivec2 param_14 = _3703;\n                        float param_15 = _3619;\n                        float param_16 = _3625;\n                        float param_17 = _3718;\n                        float param_18 = _3788;\n                        float _3803 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3803;\n                        ivec2 param_19 = _3714 + ivec2(-1, 0);\n                        ivec2 param_20 = _3703;\n                        float param_21 = _3619;\n                        float param_22 = _3625;\n                        float param_23 = _3718;\n                        float param_24 = _3803;\n                        float _3818 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3818;\n                        ivec2 param_25 = _3714 + ivec2(1, 0);\n                        ivec2 param_26 = _3703;\n                        float param_27 = _3619;\n                        float param_28 = _3625;\n                        float param_29 = _3718;\n                        float param_30 = _3818;\n                        float _3833 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3833;\n                        ivec2 param_31 = _3714 + ivec2(-1, 1);\n                        ivec2 param_32 = _3703;\n                        float param_33 = _3619;\n                        float param_34 = _3625;\n                        float param_35 = _3718;\n                        float param_36 = _3833;\n                        float _3848 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3848;\n                        ivec2 param_37 = _3714 + ivec2(0, 1);\n                        ivec2 param_38 = _3703;\n                        float param_39 = _3619;\n                        float param_40 = _3625;\n                        float param_41 = _3718;\n                        float param_42 = _3848;\n                        float _3863 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3863;\n                        ivec2 param_43 = _3714 + ivec2(1);\n                        ivec2 param_44 = _3703;\n                        float param_45 = _3619;\n                        float param_46 = _3625;\n                        float param_47 = _3718;\n                        float param_48 = _3863;\n                        float _3878 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3878;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3886;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3886 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3886 = best;\n                        }\n                        return _3886;\n                    }\n                }\n            }\n            float _3909;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3909 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3909 = 1.0;\n            }\n            return _3909;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5754 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5761;\n    if (!_5754)\n    {\n        _5761 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5761 = _5754;\n    }\n    if (_5761)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5774 = fa_light_texel(param);\n    float _5775 = _5774.y;\n    float len = _5775;\n    if (_5775 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5787 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5796 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5787);\n    if (_5796 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5802 = len;\n    float _5805 = min(_5802, 0.89999997615814208984375 * dist);\n    len = _5805;\n    float _5810 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5787);\n    float _5815 = _5810 + (0.5 * _5805);\n    vec3 _5821 = world + (gn * _5810);\n    float _5823 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5884;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5838 = (float(k) + _5823) * 0.083333335816860198974609375;\n        vec3 _5846 = _5821 + (l * (_5838 * len));\n        vec4 _5852 = vec4(_5846, 1.0);\n        float _5857 = dot(fa_mesh_fs_params[28], _5852);\n        if (_5857 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5875 = vec2(dot(fa_mesh_fs_params[26], _5852), dot(fa_mesh_fs_params[27], _5852)) / vec2(_5857);\n        float _5879 = _5875.x * 0.5;\n        float _5880 = _5879 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5884 = (_5875.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5884 = 0.5 - (_5875.y * 0.5);\n        }\n        bool _5900 = _5880 < 0.0;\n        bool _5907;\n        if (!_5900)\n        {\n            _5907 = _5880 >= 1.0;\n        }\n        else\n        {\n            _5907 = _5900;\n        }\n        bool _5914;\n        if (!_5907)\n        {\n            _5914 = _5884 < 0.0;\n        }\n        else\n        {\n            _5914 = _5907;\n        }\n        bool _5921;\n        if (!_5914)\n        {\n            _5921 = _5884 >= 1.0;\n        }\n        else\n        {\n            _5921 = _5914;\n        }\n        if (_5921)\n        {\n            break;\n        }\n        vec4 _5945 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5880, _5884) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5945.w < 0.5)\n        {\n            continue;\n        }\n        float _5963 = (dot(fa_mesh_fs_params[29].xyz, _5846) + fa_mesh_fs_params[29].w) - _5945.x;\n        if ((_5963 > _5810) && (_5963 < _5815))\n        {\n            occ = max(occ, (1.0 - (_5838 * _5838)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5880, 0.5 - _5879), min(_5884, 1.0 - _5884))));\n        }\n    }\n    return 1.0 - (occ * _5796);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6625 = fa_baked_keep(param);\n    if (_6625 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6651 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9919 = _6651.color;\n    float _9920 = _6651.attenuation;\n    float _9921 = _6651.shadow;\n    bool _6654 = _6651.type == 0;\n    if (_6654 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6651.direction;\n        float _6665 = fa_shadow_factor(param_5, param_6);\n        _9921 = _6665;\n        _9919 *= _6665;\n    }\n    else\n    {\n        bool _6676 = _6651.type != 0;\n        bool _6682;\n        if (_6676)\n        {\n            _6682 = _9920 > 0.0;\n        }\n        else\n        {\n            _6682 = _6676;\n        }\n        if (_6682)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6651.direction;\n            float _6701 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9921 = _6701;\n            _9919 *= _6701;\n        }\n    }\n    bool _6711 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6717;\n    if (_6711)\n    {\n        _6717 = _9920 > 0.0;\n    }\n    else\n    {\n        _6717 = _6711;\n    }\n    if (_6717)\n    {\n        float _6724;\n        if (_6654)\n        {\n            _6724 = 1000000000.0;\n        }\n        else\n        {\n            _6724 = _6651._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6651.direction;\n        float param_18 = _6724;\n        float _6742 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9921 *= _6742;\n        _9919 *= _6742;\n    }\n    float _6755 = _9920;\n    float _6756 = _6755 * _6625;\n    _9920 = _6756;\n    vec3 _6760 = _9919;\n    vec3 _6761 = _6760 * _6625;\n    _9919 = _6761;\n    return LightSample(_6651.direction, _6761, _6756, _9921, _6651._distance, _6651.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6795 = v - (n * dot(v, n));\n    vec3 t = _6795;\n    float _6799 = dot(_6795, _6795);\n    float l2 = _6799;\n    if (_6799 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6809;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6809 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6809 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6809;\n        l2 = dot(_6809, _6809);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7196;\n    if ((j == 0) || (j == 7))\n    {\n        _7196 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7206;\n        if ((j == 3) || (j == 4))\n        {\n            _7206 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7206 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7196 = _7206;\n    }\n    float _7227;\n    if ((j == 1) || (j == 2))\n    {\n        _7227 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7236;\n        if ((j == 5) || (j == 6))\n        {\n            _7236 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7236 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7227 = _7236;\n    }\n    return (pc + (ex * _7196)) + (ey * _7227);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6844 = dot(a, a);\n    float _6848 = dot(b, b);\n    if ((_6844 < 1.0000000195414813782625560981111e-24) || (_6848 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6862 = a * inversesqrt(_6844);\n    vec3 _6867 = b * inversesqrt(_6848);\n    float _6871 = dot(_6862, _6867);\n    float _6874 = abs(_6871);\n    float g = (((((((((((0.0416471660137176513671875 * _6874) - 0.1924748718738555908203125) * _6874) + 0.4179156124591827392578125) * _6874) - 0.616057217121124267578125) * _6874) + 0.777722418308258056640625) * _6874) - 0.999542415142059326171875) * _6874) + 1.570791721343994140625;\n    if (_6871 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6871 * _6871), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6862, _6867) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6931 = a.z > 0.0;\n    bool _6935 = b.z > 0.0;\n    if (_6931 && _6935)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6931 != _6935)\n        {\n            vec3 _6970 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6970.z = 0.0;\n            if (_6931)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6970;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6970;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6970;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6970;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7019 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7045 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7071 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7097 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7019;\n    vec3 param_1 = _7045;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7045;\n    vec3 param_7 = _7071;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7071;\n    vec3 param_13 = _7097;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7097;\n    vec3 param_19 = _7019;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7265 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7283;\n    for (int k = 0; k < (2 * _7265); k++)\n    {\n        bool _7280 = k >= _7265;\n        if (_7280)\n        {\n            _7283 = k - _7265;\n        }\n        else\n        {\n            _7283 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7265 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7329 = 2 * _7283;\n            int param_4 = _7329 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7329 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7329 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7366 = bvec4(_7280);\n        vec4 param_16 = vec4(_7366.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7366.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7366.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7366.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7377 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7280)\n        {\n            vec2 _10175 = sum;\n            _10175.y = _10175.y + _7377;\n            sum = _10175;\n        }\n        else\n        {\n            vec2 _10178 = sum;\n            _10178.x = _10178.x + _7377;\n            sum = _10178;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7401 = fa_light_base(param);\n    int param_1 = _7401;\n    int param_2 = _7401 + 1;\n    int param_3 = _7401 + 2;\n    int param_4 = _7401 + 4;\n    vec4 _7423 = fa_light_texel(param_4);\n    int param_5 = _7401 + 5;\n    vec4 _7428 = fa_light_texel(param_5);\n    int param_6 = _7401 + 6;\n    vec4 _7433 = fa_light_texel(param_6);\n    float _7434 = _7433.w;\n    vec3 _7439 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7441 = _7434 < 1.5;\n    bool _7448;\n    if (_7441)\n    {\n        _7448 = dot(normalize(fa_light_texel(param_3).xyz), _7439) >= 0.0;\n    }\n    else\n    {\n        _7448 = _7441;\n    }\n    if (_7448)\n    {\n        return vec3(0.0);\n    }\n    bool _7457 = (_7434 > 0.5) && _7441;\n    float _7461 = _7457 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7464 = _7423.xyz;\n    float _7466 = _7423.w;\n    vec3 _7472 = _7428.xyz;\n    float _7474 = _7428.w;\n    vec3 up = _7472 * (_7474 * _7461);\n    float _7480;\n    if (_7457)\n    {\n        _7480 = (3.1415927410125732421875 * _7466) * _7466;\n    }\n    else\n    {\n        _7480 = (4.0 * _7466) * _7474;\n    }\n    if (_7434 > 1.5)\n    {\n        vec3 _7506 = cross(_7464, -_7439);\n        vec3 perp = _7506;\n        float _7510 = dot(_7506, _7506);\n        vec3 _7513;\n        if (_7510 > 1.0000000133514319600180897396058e-10)\n        {\n            _7513 = perp * inversesqrt(_7510);\n        }\n        else\n        {\n            _7513 = _7472;\n        }\n        perp = _7513;\n        up = _7513 * _7474;\n    }\n    float _7534 = max(_7480, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7544 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7544;\n    vec3 param_10 = n;\n    vec3 param_11 = _7439;\n    vec3 param_12 = _7544;\n    vec3 param_13 = n;\n    vec3 param_14 = _7464 * (_7466 * _7461);\n    vec3 param_15 = _7544;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7575 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7575;\n    vec2 param_21 = _7575 + vec2(64.0, 0.0);\n    vec4 _7585 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7434;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7597 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7597.x) + (((f0 * _7585.x) + ((vec3(f90) - f0) * _7585.y)) * _7597.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7439, _7439)) + _7534) / _7534) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5491 = 1.0 / alpha;\n    return ((2.0 + _5491) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5491)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5526 = max(dot(L.nc, l), 0.0);\n    float _5532 = max(dot(L.nc, h), 0.0);\n    float _5541 = ((_5532 * _5532) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5541) * _5541)) * (0.5 / max(mix((2.0 * _5526) * L.coat_ndv, _5526 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5526)) * _5526;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7634;\n    if (L.sheen_on)\n    {\n        _7634 = L.sheen_scale;\n    }\n    else\n    {\n        _7634 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7634);\n    vec3 _7647 = normalize(l + v);\n    int param = li;\n    vec3 _7658 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7667 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7647), 0.0);\n        float param_3 = _7667;\n        float param_4 = ndv;\n        result += ((L.sheen * _7658) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7667)) * _7667) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7647;\n        float param_8 = max(dot(v, _7647), 0.0);\n        result += (_7658 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5394 = tdh / at;\n    float _5398 = bdh / ab;\n    float _5410 = ((_5394 * _5394) + (_5398 * _5398)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5410) * _5410);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5590 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5669 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5669) * _5669);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5590);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5590));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4793 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4796 = _4793.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4796 * _4796, exp2((-9.27999973297119140625) * ndv)) * _4796) + _4793.y)) + _4793.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4103;\n    if (lv == 0)\n    {\n        _4103 = 0.0;\n    }\n    else\n    {\n        _4103 = res + 2.0;\n    }\n    float _4113;\n    if (lv == 0)\n    {\n        _4113 = 0.0;\n    }\n    else\n    {\n        _4113 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4103, _4113)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4159;\n    if (res > 64.5)\n    {\n        _4159 = 5.0;\n    }\n    else\n    {\n        _4159 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4174 = clamp(rough, 0.0, 1.0) * (_4159 - 1.0);\n    int _4181 = int(min(floor(_4174), _4159 - 2.0));\n    float _4186 = _4174 - float(_4181);\n    vec3 param = d;\n    vec2 _4190 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4181;\n    vec2 param_4 = _4190;\n    vec3 _4200 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4186 < 0.00200000009499490261077880859375)\n    {\n        return _4200;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4181 + 1;\n    vec2 param_8 = _4190;\n    return mix(_4200, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4186));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4271 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4278 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4285 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4291 = dot(bx.xyz, d);\n    float _4295 = dot(by.xyz, d);\n    float _4299 = dot(bz.xyz, d);\n    float _4305;\n    if (_4291 > 9.9999999747524270787835121154785e-07)\n    {\n        _4305 = (1.0 - _4271) / _4291;\n    }\n    else\n    {\n        float _4319;\n        if (_4291 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4319 = ((-1.0) - _4271) / _4291;\n        }\n        else\n        {\n            _4319 = 1000000015047466219876688855040.0;\n        }\n        _4305 = _4319;\n    }\n    float tx = _4305;\n    float _4336;\n    if (_4295 > 9.9999999747524270787835121154785e-07)\n    {\n        _4336 = (1.0 - _4278) / _4295;\n    }\n    else\n    {\n        float _4349;\n        if (_4295 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4349 = ((-1.0) - _4278) / _4295;\n        }\n        else\n        {\n            _4349 = 1000000015047466219876688855040.0;\n        }\n        _4336 = _4349;\n    }\n    float ty = _4336;\n    float _4365;\n    if (_4299 > 9.9999999747524270787835121154785e-07)\n    {\n        _4365 = (1.0 - _4285) / _4299;\n    }\n    else\n    {\n        float _4378;\n        if (_4299 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4378 = ((-1.0) - _4285) / _4299;\n        }\n        else\n        {\n            _4378 = 1000000015047466219876688855040.0;\n        }\n        _4365 = _4378;\n    }\n    float _4390 = tx;\n    float _4393 = (_4390 > 0.0) ? _4390 : 1000000015047466219876688855040.0;\n    tx = _4393;\n    float _4394 = ty;\n    float _4397 = (_4394 > 0.0) ? _4394 : 1000000015047466219876688855040.0;\n    ty = _4397;\n    float _4407 = min(_4393, min(_4397, (_4365 > 0.0) ? _4365 : 1000000015047466219876688855040.0));\n    if (_4407 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4423 = (fa_world_pos + (d * _4407)) - posw.xyz;\n    vec3 _4428;\n    if (dot(_4423, _4423) > 1.0000000133514319600180897396058e-10)\n    {\n        _4428 = normalize(_4423);\n    }\n    else\n    {\n        _4428 = d;\n    }\n    return _4428;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4474 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4474 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4502 = rough * rough;\n            float _4533 = 0.60000002384185791015625 * _4502;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4502)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4533, 0.0500000007450580596923828125 + _4533, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4502 * 0.60000002384185791015625));\n        }\n        outc = base * _4474;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4592 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4592 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4624 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4624 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5271;\n        if (L.aniso >= 0.0)\n        {\n            _5271 = L.b;\n        }\n        else\n        {\n            _5271 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5271, v), _5271), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5307 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5307.x) + (vec3(L.f90) * _5307.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5365 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5365.x) + _5365.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4835 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4835.x) + vec3(_4835.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6067 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6071 = fa_xm_origin(param_1);\n    vec2 _6077 = (uv * _6067) - vec2(0.5);\n    vec2 _6080 = fract(_6077);\n    vec2 _6083 = floor(_6077);\n    vec2 param_2 = _6067;\n    vec2 param_3 = _6071;\n    vec2 param_4 = _6083;\n    vec2 param_5 = _6067;\n    vec2 param_6 = _6071;\n    vec2 param_7 = _6083 + vec2(1.0, 0.0);\n    vec2 param_8 = _6067;\n    vec2 param_9 = _6071;\n    vec2 param_10 = _6083 + vec2(0.0, 1.0);\n    vec2 param_11 = _6067;\n    vec2 param_12 = _6071;\n    vec2 param_13 = _6083 + vec2(1.0);\n    vec3 _6125 = vec3(_6080.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6125), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6125), vec3(_6080.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6144 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6148 = clamp(lod, 0.0, _6144);\n    int _6152 = int(floor(_6148));\n    int param = _6152;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6162 = float(_6152);\n    float _6163 = _6148 - _6162;\n    bool _6165 = _6163 > 0.001000000047497451305389404296875;\n    bool _6172;\n    if (_6165)\n    {\n        _6172 = _6162 < _6144;\n    }\n    else\n    {\n        _6172 = _6165;\n    }\n    if (_6172)\n    {\n        int param_2 = _6152 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6163));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6198 = fa_env_brdf(param, param_1);\n    vec3 _6222 = ((vec3(1.0) - clamp((f0 * _6198.x) + (vec3(f90) * _6198.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6222;\n    float _6228 = max(s.thickness, 0.0);\n    bool _6233 = _6228 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6233)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6228);\n    }\n    bool _6258 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6264;\n    if (_6258)\n    {\n        _6264 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6264 = _6258;\n    }\n    bool _6271;\n    if (!_6264)\n    {\n        _6271 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6271 = _6264;\n    }\n    if (_6271)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6286 = vec4(fa_world_pos, 1.0);\n    float _6291 = dot(fa_mesh_fs_params[28], _6286);\n    vec2 uv0 = vec2(0.5);\n    if (_6291 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6309 = vec2(dot(fa_mesh_fs_params[26], _6286), dot(fa_mesh_fs_params[27], _6286)) / vec2(_6291);\n        float _6317;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6317 = (_6309.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6317 = 0.5 - (_6309.y * 0.5);\n        }\n        uv0 = vec2((_6309.x * 0.5) + 0.5, _6317);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6338 = fa_xm_size(param_2);\n        vec2 _6346 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6338);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6346), 0).w > 0.5)\n        {\n            int _6366 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6389 = abs(dx) > _6366;\n                    bool _6397;\n                    if (!_6389)\n                    {\n                        _6397 = abs(dy) > _6366;\n                    }\n                    else\n                    {\n                        _6397 = _6389;\n                    }\n                    if (_6397)\n                    {\n                        continue;\n                    }\n                    vec4 _6418 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6346 + vec2(float(dx), float(dy)), vec2(0.0), _6338 - vec2(1.0))), 0);\n                    if (_6418.w > 0.5)\n                    {\n                        acc += _6418.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6222 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6233)\n    {\n        vec4 _6466 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6228), 1.0);\n        float _6471 = dot(fa_mesh_fs_params[28], _6466);\n        uv = vec2(0.5);\n        if (_6471 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6488 = vec2(dot(fa_mesh_fs_params[26], _6466), dot(fa_mesh_fs_params[27], _6466)) / vec2(_6471);\n            float _6496;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6496 = (_6488.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6496 = 0.5 - (_6488.y * 0.5);\n            }\n            uv = vec2((_6488.x * 0.5) + 0.5, _6496);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3290 = int(fa_shadows[25].x + 0.5);\n    float _3300 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3305 = _3290 > 0;\n    bool _3314;\n    if (_3305)\n    {\n        int param = _3290 - 1;\n        _3314 = _3300 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3314 = _3305;\n    }\n    if (_3314)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3320 = _3290 > 1;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3300 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3333 = _3290 > 2;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3300 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3346 = _3290 > 3;\n        bool _3353;\n        if (_3346)\n        {\n            _3353 = _3300 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3353 = _3346;\n        }\n        if (_3353)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9578 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9578 = -_9578;\n    }\n    vec3 _8871 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n    Surface _8879 = fa_standard_surface(param_1);\n    vec3 _9609 = _8879.albedo;\n    float _9610 = _8879.alpha;\n    vec3 _9611 = _8879.normal;\n    float _9612 = _8879.metallic;\n    float _9613 = _8879.roughness;\n    float _9614 = _8879.occlusion;\n    vec3 _9615 = _8879.emission;\n    float _9616 = _8879.clearcoat;\n    float _9617 = _8879.clearcoat_roughness;\n    vec3 _9618 = _8879.sheen_color;\n    float _9619 = _8879.sheen_roughness;\n    float _9620 = _8879.anisotropy;\n    float _9621 = _8879.anisotropy_rotation;\n    float _9622 = _8879.specular;\n    float _9623 = _8879.ior;\n    vec3 _9624 = _8879.specular_color;\n    float _9625 = _8879.transmission;\n    float _9626 = _8879.thickness;\n    vec3 _9627 = _8879.attenuation_color;\n    float _9628 = _8879.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n    Surface param_3 = _8879;\n    surface(param_2, param_3);\n    _9609 = param_3.albedo;\n    _9610 = param_3.alpha;\n    _9611 = param_3.normal;\n    _9612 = param_3.metallic;\n    _9613 = param_3.roughness;\n    _9614 = param_3.occlusion;\n    _9615 = param_3.emission;\n    _9616 = param_3.clearcoat;\n    _9617 = param_3.clearcoat_roughness;\n    _9618 = param_3.sheen_color;\n    _9619 = param_3.sheen_roughness;\n    _9620 = param_3.anisotropy;\n    _9621 = param_3.anisotropy_rotation;\n    _9622 = param_3.specular;\n    _9623 = param_3.ior;\n    _9624 = param_3.specular_color;\n    _9625 = param_3.transmission;\n    _9626 = param_3.thickness;\n    _9627 = param_3.attenuation_color;\n    _9628 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9578;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9609 = param_6;\n    _9611 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9609;\n    }\n    else\n    {\n        vec3 _8919 = normalize(_9611);\n        float _8926 = clamp(_9612, 0.0, 1.0);\n        float _8930 = clamp(_9613, 0.0500000007450580596923828125, 1.0);\n        float _8934 = _8930 * _8930;\n        float _8938 = _8934 * _8934;\n        float _8943 = max(dot(_8919, _8871), 9.9999997473787516355514526367188e-05);\n        float _8949 = 1.0 - _8926;\n        float _8950 = clamp(_9625, 0.0, 1.0) * _8949;\n        vec3 _8959 = (_9609 * _8949) * (1.0 - _8950);\n        vec3 _8966 = mix(vec3(0.039999999105930328369140625), _9609, vec3(_8926));\n        vec3 f0 = _8966;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n        Surface param_9 = Surface(_9609, _9610, _9611, _9612, _9613, _9614, _9615, _9616, _9617, _9618, _9619, _9620, _9621, _9622, _9623, _9624, _9625, _9626, _9627, _9628);\n        vec3 param_10 = _8919;\n        vec3 param_11 = _8871;\n        float param_12 = _8926;\n        float param_13 = _8930;\n        vec3 param_14 = _8966;\n        FaLayers _8982 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8919;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8959) * _9614;\n        if (_8982.on)\n        {\n            lit *= _8982.base_scale;\n        }\n        int _9004 = fa_cl_ndir + fa_cl_local;\n        float _9069;\n        for (int ln = 0; ln < _9004; ln++)\n        {\n            int param_16 = ln;\n            int _9017 = fa_cl_light(param_16);\n            int param_17 = _9017;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9017;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9578;\n            LightSample _9033 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9041 = max(dot(_8919, _9033.direction), 0.0);\n            float _9047 = _9033.attenuation * _9033.shadow;\n            vec3 _9052 = normalize(_9033.direction + _8871);\n            float _9057 = max(dot(_8919, _9052), 0.0);\n            float _9062 = max(dot(_8871, _9052), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8982.on)\n                {\n                    _9069 = _8982.f90;\n                }\n                else\n                {\n                    _9069 = 1.0;\n                }\n                int param_21 = _9017;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8919;\n                vec3 param_24 = _8871;\n                vec3 param_25 = _8959;\n                vec3 param_26 = f0;\n                float param_27 = _9069;\n                float param_28 = _8930;\n                float param_29 = _8943;\n                float param_30 = _9047;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8982.on)\n                {\n                    FaLayers param_31 = _8982;\n                    vec3 param_32 = area;\n                    int param_33 = _9017;\n                    vec3 param_34 = _8919;\n                    vec3 param_35 = _8871;\n                    vec3 param_36 = _9033.direction;\n                    float param_37 = _8943;\n                    float param_38 = _9047;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8982.on)\n                {\n                    FaLayers param_39 = _8982;\n                    vec3 param_40 = _8959;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8919;\n                    vec3 param_43 = _8871;\n                    vec3 param_44 = _9033.direction;\n                    vec3 param_45 = _9052;\n                    float param_46 = _9041;\n                    float param_47 = _8943;\n                    float param_48 = _9057;\n                    float param_49 = _9062;\n                    float param_50 = _8934;\n                    float param_51 = _8938;\n                    int param_52 = _9017;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9047));\n                }\n                else\n                {\n                    float _9171 = ((_9057 * _9057) * (_8938 - 1.0)) + 1.0;\n                    int param_53 = _9017;\n                    lit += (((_8959 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9062, 5.0))) * (((_8938 / ((3.1415927410125732421875 * _9171) * _9171)) * (0.5 / max(mix((2.0 * _9041) * _8943, _9041 + _8943, _8934), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9041))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9041 * _9047));\n                }\n            }\n        }\n        if (_8982.on)\n        {\n            FaLayers param_54 = _8982;\n            vec3 param_55 = _8919;\n            vec3 param_56 = _8871;\n            vec3 param_57 = f0;\n            float param_58 = _8930;\n            float param_59 = _9614;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8919;\n            vec3 param_61 = _8871;\n            vec3 param_62 = f0;\n            float param_63 = _8930;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9614);\n        }\n        if (_8950 > 0.0)\n        {\n            float _9269;\n            if (_8982.on)\n            {\n                _9269 = _8982.f90;\n            }\n            else\n            {\n                _9269 = 1.0;\n            }\n            float _9277;\n            if (_8982.on)\n            {\n                _9277 = _8982.base_scale;\n            }\n            else\n            {\n                _9277 = 1.0;\n            }\n            Surface param_64 = Surface(_9609, _9610, _9611, _9612, _9613, _9614, _9615, _9616, _9617, _9618, _9619, _9620, _9621, _9622, _9623, _9624, _9625, _9626, _9627, _9628);\n            vec3 param_65 = _8919;\n            vec3 param_66 = _8871;\n            float param_67 = _8930;\n            vec3 param_68 = f0;\n            float param_69 = _9269;\n            float param_70 = _9277;\n            float param_71 = _8950;\n            float param_72 = fa_tr_blend;\n            vec3 _9301 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9301;\n        }\n        result = lit;\n    }\n    vec3 _9308 = result;\n    vec3 _9309 = _9308 + _9615;\n    result = _9309;\n    vec3 param_73 = _9309;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9325;\n    if (!_9318)\n    {\n        _9325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9325 = _9318;\n    }\n    if (_9325)\n    {\n        vec3 _9334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9340 = dot(_9334, fa_mesh_fs_params[9].xyz);\n        bool _9344 = fa_mesh_fs_params[9].w > 0.5;\n        float _9345;\n        if (_9344)\n        {\n            _9345 = _9340;\n        }\n        else\n        {\n            _9345 = length(_9334);\n        }\n        float _9357 = _9345 - fa_mesh_fs_params[8].x;\n        if (_9357 > 0.0)\n        {\n            float _9366 = fa_mesh_fs_params[7].w * _9357;\n            float tau = _9366 * _9366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9382;\n                if (_9344)\n                {\n                    _9382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9340);\n                }\n                else\n                {\n                    _9382 = fa_mesh_fs_params[0].y;\n                }\n                float _9403 = mix(_9382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9345, 0.0, 1.0));\n                float _9407 = fa_world_pos.y - _9403;\n                float _9412 = _9403 - fa_mesh_fs_params[8].z;\n                float _9417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9420 = _9412 <= 0.0;\n                bool _9421 = !_9420;\n                bool _9427;\n                if (_9421)\n                {\n                    _9427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9427 = _9420;\n                }\n                float _9428;\n                if (_9427)\n                {\n                    _9428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9412, 80.0));\n                }\n                bool _9455;\n                if (_9421)\n                {\n                    _9455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9455 = _9420;\n                }\n                float _9456;\n                if (_9455)\n                {\n                    _9456 = fa_mesh_fs_params[8].y * _9412;\n                }\n                else\n                {\n                    _9456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9481 = _9417 <= 0.0;\n                bool _9488;\n                if (!_9481)\n                {\n                    _9488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9488 = _9481;\n                }\n                float _9489;\n                if (_9488)\n                {\n                    _9489 = fa_mesh_fs_params[8].y * _9417;\n                }\n                else\n                {\n                    _9489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9516;\n                if (abs(_9407) < 0.001000000047497451305389404296875)\n                {\n                    _9516 = _9428;\n                }\n                else\n                {\n                    _9516 = (_9489 - _9456) / _9407;\n                }\n                tau += (_9357 * max(_9516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9552 = 1.0 - fa_tr_blend;\n        result /= vec3(_9552);\n        _9610 *= _9552;\n    }\n    fa_frag_color = vec4(result, _9610);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_669",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2331",
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
              "name": "fa_probe_atlas",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4936[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1607 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1614;\n    if (!_1607)\n    {\n        _1614 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1614 = _1607;\n    }\n    bool _1622;\n    if (!_1614)\n    {\n        _1622 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1622 = _1614;\n    }\n    bool _1629;\n    if (!_1622)\n    {\n        _1629 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1629 = _1622;\n    }\n    bool _1636;\n    if (!_1629)\n    {\n        _1636 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1636 = _1629;\n    }\n    if (_1636)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1646 = vec4(world_pos, 1.0);\n    float _1652 = dot(fa_mesh_fs_params[16], _1646);\n    if (!(_1652 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1674 = vec2(dot(fa_mesh_fs_params[14], _1646), dot(fa_mesh_fs_params[15], _1646)) / vec2(_1652);\n    int _1678 = int(fa_mesh_fs_params[18].x);\n    int _1682 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1682) + clamp(int(floor(((_1674.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1682 - 1)) * _1678)) + clamp(int(floor(((_1674.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1678 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1758 = fa_cluster_texel(param);\n    return ivec2(int(_1758.x), int(_1758.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6570 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6573 = fwidth(_6570);\n    bool _6576 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6583;\n    if (!_6576)\n    {\n        _6583 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6583 = _6576;\n    }\n    if (_6583)\n    {\n        fa_rt_slope = min(1.5 * _6573, 0.100000001490116119384765625 * _6570);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6599 = fa_cluster_lookup(param);\n    fa_cl_slot = _6599.x;\n    fa_cl_local = _6599.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7773 = fa_linear_to_srgb(param);\n        c = _7773;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7781 = fa_srgb_to_linear(param_1);\n            c = _7781;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _552;\n    if (i.front_facing)\n    {\n        _552 = i.world_normal;\n    }\n    else\n    {\n        _552 = -i.world_normal;\n    }\n    vec3 _576 = normalize(i.world_tangent.xyz - (_552 * dot(_552, i.world_tangent.xyz)));\n    vec3 _603 = normalize(((_576 * m.x) + ((cross(_552, _576) * i.world_tangent.w) * m.y)) + (_552 * m.z));\n    vec3 _606;\n    if (i.front_facing)\n    {\n        _606 = _603;\n    }\n    else\n    {\n        _606 = -_603;\n    }\n    return _606;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7813 = fa_tex_fix(param_2, param_3);\n    vec4 _10192 = base_t;\n    _10192.x = _7813.x;\n    _10192.y = _7813.y;\n    _10192.z = _7813.z;\n    base_t = _10192;\n    vec4 _7827 = (_10192 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9939 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7861 = fa_tex_fix(param_6, param_7);\n        vec3 _7864 = (_7861 * 2.0) - vec3(1.0);\n        vec2 _7869 = _7864.xy * fa_mesh_fs_params[6].x;\n        vec3 _10200 = _7864;\n        _10200.x = _7869.x;\n        _10200.y = _7869.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10200;\n        _9939 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7899 = fa_tex_fix(param_12, param_13);\n    vec4 _10203 = mrt;\n    _10203.x = _7899.x;\n    _10203.y = _7899.y;\n    _10203.z = _7899.z;\n    mrt = _10203;\n    vec4 _7929 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7929.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7940 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7972 = fa_tex_fix(param_20, param_21);\n    float _9944 = fa_mesh_fs_params[20].x;\n    float _9945 = fa_mesh_fs_params[20].y;\n    float _9948 = fa_mesh_fs_params[20].z;\n    float _9947 = fa_mesh_fs_params[21].w;\n    float _9950 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9944 *= _7940.y;\n            _9945 *= _7940.z;\n            _9947 *= _7929.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9948 *= mrt.x;\n            _9950 *= mrt.w;\n        }\n    }\n    return Surface(_7827.xyz, _7827.w, _9939, clamp(fa_mesh_fs_params[5].x * _7899.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7899.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7940.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7972), _9944, _9945, fa_mesh_fs_params[21].xyz, _9947, _9948, fa_mesh_fs_params[20].w, _9950, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1838 = rect.zw - rect.xy;\n    vec2 _1842 = _1838 * atlas;\n    vec2 _1846 = ddx * _1842;\n    vec2 _1850 = ddy * _1842;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1838), clamp(0.5 * log2(max(max(dot(_1846, _1846), dot(_1850, _1850)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1883 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1890;\n    if (!_1883)\n    {\n        _1890 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1890 = _1883;\n    }\n    if (_1890)\n    {\n        return;\n    }\n    vec3 _1896 = dFdx(world_pos);\n    vec3 _1899 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1903 = fa_cluster_texel(param);\n    int _1907 = int(_1903.w);\n    if (_1907 < 1)\n    {\n        return;\n    }\n    int _1917 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1917;\n    vec4 _1921 = fa_light_texel(param_1);\n    vec2 _1924 = _1921.yz;\n    int _1928 = int(_1921.w);\n    int param_2 = _1917 + 1;\n    vec4 _1933 = fa_light_texel(param_2);\n    float _1934 = _1933.x;\n    int _1940 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1944 = int(_1903.z);\n    vec3 _2209;\n    for (int k = 0; k < _1907; k++)\n    {\n        int _1957 = _1944 + k;\n        int param_3 = _1928 + (_1957 >> 2);\n        int _1974 = (_1917 + 2) + (int(fa_light_texel(param_3)[_1957 & 3]) * 7);\n        int param_4 = _1974 + 6;\n        vec4 _1979 = fa_light_texel(param_4);\n        if (((int(_1979.w + 0.5) >> _1940) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1974;\n        vec4 _1994 = fa_light_texel(param_5);\n        int param_6 = _1974 + 1;\n        vec4 _1999 = fa_light_texel(param_6);\n        int param_7 = _1974 + 2;\n        vec4 _2004 = fa_light_texel(param_7);\n        vec3 _2007 = _1994.xyz;\n        float _2012 = dot(_2007, world_pos) + _1994.w;\n        vec3 _2014 = _1999.xyz;\n        float _2019 = dot(_2014, world_pos) + _1999.w;\n        vec3 _2021 = _2004.xyz;\n        float _2026 = dot(_2021, world_pos) + _2004.w;\n        bool _2031 = abs(_2012) > 0.5;\n        bool _2039;\n        if (!_2031)\n        {\n            _2039 = abs(_2019) > 0.5;\n        }\n        else\n        {\n            _2039 = _2031;\n        }\n        bool _2047;\n        if (!_2039)\n        {\n            _2047 = abs(_2026) > 0.5;\n        }\n        else\n        {\n            _2047 = _2039;\n        }\n        if (_2047)\n        {\n            continue;\n        }\n        float _2062 = clamp(dot(geo_normal, normalize(_2021)) * _1979.z, 0.0, 1.0);\n        if (_2062 <= 0.0)\n        {\n            continue;\n        }\n        float _2082 = (clamp((0.5 - abs(_2026)) * 10.0, 0.0, 1.0) * _2062) * _1979.x;\n        vec2 _2090 = vec2(_2012 + 0.5, 0.5 - _2019);\n        vec2 _2100 = vec2(dot(_2007, _1896), dot(_2014, _1896));\n        vec2 _2110 = vec2(dot(_2007, _1899), dot(_2014, _1899));\n        int param_8 = _1974 + 5;\n        vec4 _2115 = fa_light_texel(param_8);\n        int param_9 = _1974 + 3;\n        vec4 _2120 = fa_light_texel(param_9);\n        int param_10 = _1974 + 4;\n        vec4 _2125 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2115.xyz;\n        bool _2135 = _2120.z > _2120.x;\n        if (_2135)\n        {\n            vec4 param_11 = _2120;\n            vec2 param_12 = _2090;\n            vec2 param_13 = _1924;\n            vec2 param_14 = _2100;\n            vec2 param_15 = _2110;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1934 > 0.5) && (_1934 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2161 = fa_dc_to_linear(param_16);\n                vec4 _10027 = tx;\n                _10027.x = _2161.x;\n                _10027.y = _2161.y;\n                _10027.z = _2161.z;\n                tx = _10027;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2082 * tex_a) * _2115.w, 0.0, 1.0)));\n        if (_2125.z > _2125.x)\n        {\n            vec4 param_17 = _2125;\n            vec2 param_18 = _2090;\n            vec2 param_19 = _1924;\n            vec2 param_20 = _2100;\n            vec2 param_21 = _2110;\n            vec4 _2205 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1934 > 1.5)\n            {\n                vec3 param_22 = _2205.xyz;\n                vec3 _2215 = fa_dc_to_srgb(param_22);\n                _2209 = _2215;\n            }\n            else\n            {\n                _2209 = _2205.xyz;\n            }\n            vec3 _2224 = (_2209 * 2.0) - vec3(1.0);\n            vec2 _2229 = _2224.xy * _1979.y;\n            vec3 _2251 = (normalize(_2007) * _2229.x) + (normalize(_2014) * _2229.y);\n            vec3 _2254 = normalize(normal);\n            normal = normalize(mix(_2254, normalize((_2254 * max(_2224.z, 0.0500000007450580596923828125)) + (_2251 - (_2254 * dot(_2254, _2251)))), vec3(clamp(_2082 * (_2135 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4861 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4869 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4872 = int(_4861);\n    int _4875 = int(_4869);\n    float _4885 = _4869 - float(_4875);\n    int _4940 = (_4872 * 9) + _4875;\n    int _4960 = ((_4872 + 1) * 9) + _4875;\n    return mix(mix(_4936[_4940], _4936[_4940 + 1], _4885), mix(_4936[_4960], _4936[_4960 + 1], _4885), _4861 - float(_4872));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9862 = false;\n    float _9863 = 1.0;\n    float _9864 = 1.0;\n    float _9865 = 1.0;\n    float _9866 = 0.0;\n    float _9867 = 0.0;\n    float _9868 = 0.0;\n    float _9869 = 0.0;\n    float _9871 = 1.0;\n    bool _9872 = false;\n    vec3 _9873 = vec3(0.0);\n    float _9874 = 1.0;\n    float _9875 = 1.0;\n    float _9876 = 1.0;\n    float _9877 = 0.0;\n    float _9878 = 0.0;\n    vec3 _9879 = vec3(1.0, 0.0, 0.0);\n    vec3 _9880 = vec3(0.0, 0.0, 1.0);\n    float _9881 = 1.0;\n    float _9882 = 1.0;\n    float _5011 = clamp(s.specular, 0.0, 1.0);\n    float _5015 = clamp(s.ior, 1.0, 3.0);\n    bool _5020 = (_5011 != 1.0) || (_5015 != 1.5);\n    bool _5029;\n    if (!_5020)\n    {\n        _5029 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5029 = _5020;\n    }\n    if (_5029)\n    {\n        float _5037 = (_5015 - 1.0) / (_5015 + 1.0);\n        f0 = mix(min(vec3(_5037 * _5037) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5011, s.albedo, vec3(metallic));\n        _9863 = mix(_5011, 1.0, metallic);\n        _9862 = true;\n    }\n    float _5064 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5064 > 0.0)\n    {\n        float _5072 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9866 = _5064;\n        _9867 = _5072;\n        float _5079 = _5072 * _5072;\n        _9868 = _5079;\n        _9869 = _5079 * _5079;\n        float _5091 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9871 = _5091;\n        _9864 = 1.0 - (_5064 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5091, 0.0, 1.0), 5.0))));\n        _9862 = true;\n    }\n    vec3 _5110 = max(s.sheen_color, vec3(0.0));\n    float _5119 = max(_5110.x, max(_5110.y, _5110.z));\n    if (_5119 > 0.0)\n    {\n        float _5127 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9872 = true;\n        _9873 = _5110;\n        _9874 = _5127;\n        _9875 = _5127 * _5127;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5127;\n        float _5144 = fa_sheen_albedo(param, param_1);\n        _9877 = _5144;\n        _9876 = 1.0 - min(_5119 * _5144, 1.0);\n        _9862 = true;\n    }\n    _9865 = _9864 * _9876;\n    float _5163 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5163 != 0.0)\n    {\n        vec3 _5178 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5178;\n        if (dot(_5178, _5178) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5190 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5190.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5190.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5190.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5194 = t;\n        vec3 _5195 = normalize(_5194);\n        t = _5195;\n        vec3 _5220 = normalize((_5195 * cos(s.anisotropy_rotation)) + ((cross(n, _5195) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9879 = _5220;\n        _9880 = cross(n, _5220);\n        float _5230 = roughness * roughness;\n        float _5236 = mix(_5230, 1.0, _5163 * _5163);\n        bool _5238 = _5163 > 0.0;\n        _9881 = _5238 ? _5236 : _5230;\n        _9882 = _5238 ? _5230 : _5236;\n        _9878 = _5163;\n        _9862 = true;\n    }\n    return FaLayers(_9862, _9863, _9864, _9865, _9866, _9867, _9868, _9869, i.world_normal, _9871, _9872, _9873, _9874, _9875, _9876, _9877, _9878, _9879, _9880, _9881, _9882);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4031 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4031;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4642 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4647 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4642 > 0.0005000000237487256526947021484375)\n    {\n        if (_4647)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4642;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4642;\n        }\n    }\n    bool _4698 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4698)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4729 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4729)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4647 || _4698) || _4729)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4051 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4054 = _4051.x;\n    float _4056 = _4051.z;\n    vec2 e = vec2(_4054, _4056);\n    if (_4051.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4056)) * ((_4054 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4054)) * ((_4056 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8082 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8087 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8092 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8097 = fa_light_texel(param_3);\n    bool _8100 = _8097.z < 0.5;\n    bool _8108;\n    if (!_8100)\n    {\n        _8108 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8108 = _8100;\n    }\n    if (_8108)\n    {\n        return vec3(0.0);\n    }\n    float _8115 = max(_8082.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8118 = _8087.xyz;\n    vec3 _8122 = _8082.xyz;\n    vec3 _8126 = (fa_world_pos - _8122) / vec3(_8115);\n    vec3 _8135 = min(_8126 + vec3(0.5), (_8118 - vec3(0.5)) - _8126);\n    float _8144 = min(_8135.x, min(_8135.y, _8135.z));\n    if (!(_8144 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8159 = _8118 - vec3(1.0);\n    vec3 _8160 = clamp(_8126, vec3(0.0), _8159);\n    vec3 _8168 = min(floor(_8160), max(_8118 - vec3(2.0), vec3(0.0)));\n    vec3 _8172 = _8160 - _8168;\n    vec3 _8183 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8115));\n    int _8188 = int(_8092.y + 0.5);\n    float _8193 = 0.3257350027561187744140625 * n.y;\n    float _8197 = 0.3257350027561187744140625 * n.z;\n    float _8201 = 0.3257350027561187744140625 * n.x;\n    float _8208 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8215 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8224 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8231 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8244 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8251 = 8 + int(_8097.w);\n    float _8278;\n    float _8291;\n    float _8305;\n    for (int k = 0; k < _8251; k++)\n    {\n        float _8264 = float(k & 1);\n        float _8268 = float((k >> 1) & 1);\n        float _8272 = float((k >> 2) & 1);\n        if (_8264 > 0.5)\n        {\n            _8278 = _8172.x;\n        }\n        else\n        {\n            _8278 = 1.0 - _8172.x;\n        }\n        if (_8268 > 0.5)\n        {\n            _8291 = _8172.y;\n        }\n        else\n        {\n            _8291 = 1.0 - _8172.y;\n        }\n        if (_8272 > 0.5)\n        {\n            _8305 = _8172.z;\n        }\n        else\n        {\n            _8305 = 1.0 - _8172.z;\n        }\n        float _8315 = (_8278 * _8291) * _8305;\n        if (!(_8315 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8328 = min(_8168 + vec3(_8264, _8268, _8272), _8159);\n        int _8348 = int(((_8092.x + _8328.x) + (_8087.x * (_8328.y + (_8087.y * _8328.z)))) + 0.5);\n        vec2 _8363 = vec2(float(_8348 % _8188) * 10.0, 1024.0 + (float(_8348 / _8188) * 11.0));\n        vec2 param_4 = _8363 + vec2(9.5, 10.5);\n        vec4 _8371 = fa_gi_fetch(param_4);\n        bool _8374 = _8371.y < 0.5;\n        bool _8383;\n        if (!_8374)\n        {\n            _8383 = _8371.x > _8097.y;\n        }\n        else\n        {\n            _8383 = _8374;\n        }\n        if (_8383)\n        {\n            continue;\n        }\n        vec3 _8395 = _8183 - (_8122 + (_8328 * _8115));\n        float _8398 = length(_8395);\n        vec3 _8404 = _8395 / vec3(max(_8398, 9.9999997473787516355514526367188e-05));\n        float _8414 = max(9.9999997473787516355514526367188e-05, (dot(-_8404, n) + 1.0) * 0.5);\n        float w = _8315 * (_8414 * _8414);\n        vec3 param_5 = _8404;\n        vec2 param_6 = (_8363 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8433 = fa_gi_fetch(param_6);\n        float _8440 = _8398 / max(_8092.z, 9.9999997473787516355514526367188e-05);\n        float _8443 = _8433.x;\n        if (_8440 > _8443)\n        {\n            float _8456 = max(_8433.y - (_8443 * _8443), 0.0);\n            float _8461 = _8440 - _8443;\n            float _8470 = _8456 / max(_8456 + (_8461 * _8461), 9.9999999600419720025001879548654e-13);\n            w *= ((_8470 * _8470) * _8470);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8363 + vec2(0.5, 10.5);\n        vec2 param_8 = _8363 + vec2(1.5, 10.5);\n        vec2 param_9 = _8363 + vec2(2.5, 10.5);\n        vec2 param_10 = _8363 + vec2(3.5, 10.5);\n        vec2 param_11 = _8363 + vec2(4.5, 10.5);\n        vec2 param_12 = _8363 + vec2(5.5, 10.5);\n        vec2 param_13 = _8363 + vec2(6.5, 10.5);\n        vec2 param_14 = _8363 + vec2(7.5, 10.5);\n        vec2 param_15 = _8363 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8193)) + (fa_gi_fetch(param_9).xyz * _8197)) + (fa_gi_fetch(param_10).xyz * _8201)) + (fa_gi_fetch(param_11).xyz * _8208)) + (fa_gi_fetch(param_12).xyz * _8215)) + (fa_gi_fetch(param_13).xyz * _8224)) + (fa_gi_fetch(param_14).xyz * _8231)) + (fa_gi_fetch(param_15).xyz * _8244)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8144 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8595;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8595 = _8097.x;\n    }\n    else\n    {\n        _8595 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8092.w * _8595);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8619 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8624 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8629 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8629) && (k < 8); k++)\n    {\n        int param = _8624 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8619;\n        vec3 _8654 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8659 = param_3 * left;\n        acc += (_8654 * _8659);\n        left -= _8659;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8688 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8688;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8730 = vec4(fa_world_pos, 1.0);\n        vec2 _8749 = vec2(dot(fa_mesh_fs_params[26], _8730), dot(fa_mesh_fs_params[27], _8730)) / vec2(max(dot(fa_mesh_fs_params[28], _8730), 9.9999997473787516355514526367188e-05));\n        float _8758;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8758 = (_8749.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8758 = 0.5 - (_8749.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8749.x * 0.5) + 0.5, _8758) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6540;\n    if (fa_lm.z > 0.5)\n    {\n        _6540 = 0.0;\n    }\n    else\n    {\n        _6540 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6551 = _6540 < 1.0;\n    bool _6557;\n    if (_6551)\n    {\n        int param = li;\n        _6557 = fa_light_baked(param);\n    }\n    else\n    {\n        _6557 = _6551;\n    }\n    return _6557 ? _6540 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _856 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _869 = (c - (ru * hx)) - p;\n        vec3 _875 = ru * (2.0 * hx);\n        float _881 = max(dot(_875, _875), 9.9999999392252902907785028219223e-09);\n        float _885 = dot(_869, _875);\n        float t = clamp((-_885) / _881, 0.0, 1.0);\n        if (_856)\n        {\n            float _900 = dot(r, _875);\n            float _906 = _881 - (_900 * _900);\n            if (abs(_906) > (9.9999997473787516355514526367188e-06 * _881))\n            {\n                t = clamp(((dot(r, _869) * _900) - _885) / _906, 0.0, 1.0);\n            }\n        }\n        return (p + _869) + (_875 * t);\n    }\n    vec3 q = p;\n    float _938 = dot(r, axis);\n    bool _946;\n    if (_856)\n    {\n        _946 = abs(_938) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _946 = _856;\n    }\n    if (_946)\n    {\n        float _956 = dot(c - p, axis) / _938;\n        if (_956 > 0.0)\n        {\n            q = p + (r * _956);\n        }\n    }\n    vec3 _969 = q - c;\n    vec2 xy = vec2(dot(_969, ru), dot(_969, uu));\n    if (shape > 0.5)\n    {\n        float _984 = length(xy);\n        if (_984 > hx)\n        {\n            xy *= (hx / _984);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _618 = abs(d);\n    float _620 = _618.x;\n    float _622 = _618.y;\n    bool _623 = _620 >= _622;\n    bool _631;\n    if (_623)\n    {\n        _631 = _620 >= _618.z;\n    }\n    else\n    {\n        _631 = _623;\n    }\n    int _632;\n    if (_631)\n    {\n        _632 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _646;\n        if (_622 >= _618.z)\n        {\n            _646 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _646 = (d.z > 0.0) ? 4 : 5;\n        }\n        _632 = _646;\n    }\n    return _632;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _776 = dot(d, right);\n    float _780 = dot(d, up);\n    float _791;\n    if (((_776 * _776) + (_780 * _780)) > 1.0000000133514319600180897396058e-10)\n    {\n        _791 = atan(_780, _776) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _791 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_791 - floor(_791)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1022 = fa_light_base(param);\n    bool _1026 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1022;\n    vec4 _1030 = fa_light_texel(param_1);\n    int param_2 = _1022 + 1;\n    vec4 _1035 = fa_light_texel(param_2);\n    float _1038 = _1035.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1050 = _1026 && (_1038 > 2.5);\n    fa_light_is_area = _1050;\n    bool _1052 = _1038 < 0.5;\n    vec3 l;\n    if (_1052)\n    {\n        l = normalize(_1030.xyz);\n        if (_1026)\n        {\n            int param_3 = _1022 + 6;\n            vec4 _1066 = fa_light_texel(param_3);\n            if (_1066.z > 0.5)\n            {\n                int param_4 = _1022 + 4;\n                vec4 _1076 = fa_light_texel(param_4);\n                int param_5 = _1022 + 5;\n                vec4 _1081 = fa_light_texel(param_5);\n                vec2 param_6 = _1066.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1076.xyz) * _1076.w, (-dot(world_pos, _1081.xyz)) * _1081.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1111 = _1030.xyz;\n        vec3 _1113 = _1111 - world_pos;\n        vec3 to_light = _1113;\n        float _1116 = length(_1113);\n        float reach = _1116;\n        bool front = true;\n        if (_1050)\n        {\n            int param_8 = _1022 + 7;\n            reach = max(_1116 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1022 + 4;\n            vec4 _1140 = fa_light_texel(param_9);\n            int param_10 = _1022 + 5;\n            vec4 _1145 = fa_light_texel(param_10);\n            int param_11 = _1022 + 6;\n            vec4 _1150 = fa_light_texel(param_11);\n            float _1151 = _1150.w;\n            int param_12 = _1022 + 2;\n            vec3 _1158 = normalize(fa_light_texel(param_12).xyz);\n            bool _1160 = _1151 > 1.5;\n            bool _1168;\n            if (!_1160)\n            {\n                _1168 = dot(_1158, to_light) < 0.0;\n            }\n            else\n            {\n                _1168 = _1160;\n            }\n            front = _1168;\n            vec3 r = vec3(0.0);\n            vec3 _1177 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1181 = dot(n, n) > 0.5;\n            bool _1189;\n            if (_1181)\n            {\n                _1189 = dot(_1177, _1177) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1189 = _1181;\n            }\n            if (_1189)\n            {\n                r = reflect(-normalize(_1177), normalize(n));\n            }\n            vec3 param_13 = _1111;\n            vec3 param_14 = _1158;\n            vec3 param_15 = _1140.xyz;\n            vec3 param_16 = _1145.xyz;\n            float param_17 = _1140.w;\n            float param_18 = _1145.w;\n            float param_19 = _1151;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1225 = length(to_light);\n        dist = _1225;\n        l = to_light / vec3(max(_1225, 9.9999997473787516355514526367188e-05));\n        float _1239 = reach / max(_1030.w, 0.001000000047497451305389404296875);\n        float _1245 = clamp(1.0 - (_1239 * _1239), 0.0, 1.0);\n        float _1247;\n        if (front)\n        {\n            _1247 = _1245 * _1245;\n        }\n        else\n        {\n            _1247 = 0.0;\n        }\n        atten = _1247;\n        bool _1258 = _1038 < 2.5;\n        if ((_1038 > 1.5) && _1258)\n        {\n            int param_22 = _1022 + 2;\n            vec4 _1266 = fa_light_texel(param_22);\n            float _1276 = _1266.w;\n            int param_23 = _1022 + 3;\n            vec4 _1281 = fa_light_texel(param_23);\n            float _1282 = _1281.x;\n            float cos_inner = _1282;\n            if (_1282 > 1.5)\n            {\n                cos_inner = mix(_1276, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1276, cos_inner, dot(-l, normalize(_1266.xyz)));\n        }\n        if (_1026 && (_1038 < 1.5))\n        {\n            int param_24 = _1022 + 6;\n            vec4 _1306 = fa_light_texel(param_24);\n            if (_1306.z > 0.5)\n            {\n                vec3 _1314 = -to_light;\n                int param_25 = _1022 + 4;\n                int param_26 = _1022 + 5;\n                vec3 _1328 = fa_light_texel(param_25).xyz;\n                vec3 _1332 = fa_light_texel(param_26).xyz;\n                vec3 _1341 = vec3(dot(_1314, _1328), dot(_1314, _1332), dot(_1314, cross(_1328, _1332)));\n                vec3 param_27 = _1341;\n                int _1345 = fa_cube_face(param_27);\n                int param_28 = _1345;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1372 = vec2(dot(_1341, cross(param_29, param_30)), dot(_1341, param_30)) / vec2(max(dot(_1341, param_29), 9.9999997473787516355514526367188e-05));\n                int _1376 = _1345 / 3;\n                vec2 param_31 = _1306.xy + (vec2(float(_1345 - (_1376 * 3)), float(_1376)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1372.x), 0.5 - (0.5 * _1372.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1022 + 7;\n            vec4 _1406 = fa_light_texel(param_33);\n            if (_1406.z > 0.5)\n            {\n                int param_34 = _1022 + 2;\n                int param_35 = _1022 + 4;\n                int param_36 = _1022 + 5;\n                vec2 param_37 = _1406.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1026 && _1258)\n            {\n                int param_42 = _1022 + 6;\n                vec4 _1453 = fa_light_texel(param_42);\n                int param_43 = _1022 + 7;\n                vec4 _1458 = fa_light_texel(param_43);\n                bool _1461 = _1453.z > 0.5;\n                bool _1468;\n                if (!_1461)\n                {\n                    _1468 = _1458.z > 0.5;\n                }\n                else\n                {\n                    _1468 = _1461;\n                }\n                if (_1468)\n                {\n                    int param_44 = _1022 + 2;\n                    vec4 _1475 = fa_light_texel(param_44);\n                    vec3 _1479 = normalize(_1475.xyz);\n                    int param_45 = _1022 + 4;\n                    vec4 _1484 = fa_light_texel(param_45);\n                    int param_46 = _1022 + 5;\n                    vec4 _1489 = fa_light_texel(param_46);\n                    if (_1461)\n                    {\n                        vec3 _1497 = -to_light;\n                        float _1504 = _1475.w;\n                        float _1520 = 0.5 / max(dot(_1497, _1479) * (sqrt(max(1.0 - (_1504 * _1504), 0.0)) / max(_1504, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1453.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1497, _1484.xyz) * _1520), 0.5 - (dot(_1497, _1489.xyz) * _1520));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1458.z > 0.5)\n                    {\n                        vec2 param_49 = _1458.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1479;\n                        vec3 param_52 = _1484.xyz;\n                        vec3 param_53 = _1489.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9850 = _1035.xyz * atten;\n    if (_1026)\n    {\n        _9850 *= fa_light_tint;\n    }\n    int _1589;\n    if (_1052)\n    {\n        _1589 = 0;\n    }\n    else\n    {\n        _1589 = ((_1038 > 1.5) && (_1038 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9850, atten, 1.0, dist, _1589);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2321;\n    if (i == 0)\n    {\n        _2321 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2337;\n        if (i == 1)\n        {\n            _2337 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2345;\n            if (i == 2)\n            {\n                _2345 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2345 = fa_shadows[24].w;\n            }\n            _2337 = _2345;\n        }\n        _2321 = _2337;\n    }\n    return _2321;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2378 = fa_shadow_depth(param, param_1);\n    float _2382;\n    if (conv.x < 0.5)\n    {\n        _2382 = _2378;\n    }\n    else\n    {\n        _2382 = (conv.y * conv.z) / (conv.z - (_2378 * (conv.z - conv.y)));\n    }\n    return _2382;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2428 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2434 = vec2(cos(_2428), sin(_2428));\n    vec2 dir = _2434;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2443;\n        if (k < 0.0)\n        {\n            _2443 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2443 = k;\n        }\n        float _2462 = clamp((_2443 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2481 = sqrt((float(i) + 0.5) * 0.0625) * _2462;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2481));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2495 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2495 < (zr - (_2481 * plane)))\n            {\n                sum += _2495;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2523 = sum / cnt;\n        float _2533;\n        if (k < 0.0)\n        {\n            _2533 = (-k) / max(_2523, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2533 = k;\n        }\n        radius = clamp(((max(zr - _2523, 0.0) * unit) * _2533) / texel_m, 1.5, 16.0);\n        dir = _2434;\n    }\n    float lit = 0.0;\n    int _2559 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2559; i_1++)\n    {\n        float _2578 = sqrt((float(i_1) + 0.5) / float(_2559)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2578));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2578 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2559);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2624 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2629 = clamp(dot(n, l), 0.0, 1.0);\n    float _2635 = sqrt(1.0 - (_2629 * _2629));\n    float _2643 = min(_2635 / max(_2629, 0.20000000298023223876953125), 4.0);\n    float _2648;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2648 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2648 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2673 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2648 * _2635)), 1.0);\n    float _2680 = _2673.x;\n    bool _2683 = _2680 < fa_shadows[ci * 1 + 16].x;\n    bool _2692;\n    if (!_2683)\n    {\n        _2692 = _2680 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2692 = _2683;\n    }\n    bool _2701;\n    if (!_2692)\n    {\n        _2701 = _2673.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2701 = _2692;\n    }\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2673.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2717;\n    if (!_2710)\n    {\n        _2717 = _2673.z > 1.0;\n    }\n    else\n    {\n        _2717 = _2710;\n    }\n    if (_2717)\n    {\n        return -1.0;\n    }\n    float _2725;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2725 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2725 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2673.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2673.z - ((_2725 * (1.0 + (0.5 * _2643))) / _2624);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2624;\n    float param_5 = _2624 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2643, 3.0)) * 0.5) / _2624;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3103 = int(fa_shadows[25].x + 0.5);\n    if (_3103 < 1)\n    {\n        return 1.0;\n    }\n    float _3118 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3103 - 1;\n    if (_3118 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3130 = _3103 > 1;\n    bool _3137;\n    if (_3130)\n    {\n        _3137 = _3118 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3137 = _3130;\n    }\n    if (_3137)\n    {\n        ci = 1;\n    }\n    bool _3141 = _3103 > 2;\n    bool _3148;\n    if (_3141)\n    {\n        _3148 = _3118 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3148 = _3141;\n    }\n    if (_3148)\n    {\n        ci = 2;\n    }\n    bool _3152 = _3103 > 3;\n    bool _3159;\n    if (_3152)\n    {\n        _3159 = _3118 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3159 = _3152;\n    }\n    if (_3159)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3170 = min(_3103, 4);\n    float _3211;\n    for (int c = ci; c < _3170; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3190 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3190;\n            break;\n        }\n        if (_3190 < 0.0)\n        {\n            continue;\n        }\n        s = _3190;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3211 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3211 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3230 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3211, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3118 - (fa_shadow_split_at(param_7) - _3230)) / _3230, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3262;\n        if ((ci + 1) < _3103)\n        {\n            _3262 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3262 = 1.0;\n        }\n        s = mix(s, _3262, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3367 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3373;\n    if (_3367)\n    {\n        _3373 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3373 = _3367;\n    }\n    if (_3373)\n    {\n        float _3387 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3395 = vec4(fa_world_pos, 1.0);\n        float _3401 = dot(fa_mesh_fs_params[28], _3395);\n        if (_3401 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3420 = vec2(dot(fa_mesh_fs_params[26], _3395), dot(fa_mesh_fs_params[27], _3395)) / vec2(_3401);\n            float _3425 = (_3420.x * 0.5) + 0.5;\n            float _3429;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3429 = (_3420.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3429 = 0.5 - (_3420.y * 0.5);\n            }\n            bool _3445 = _3425 >= 0.0;\n            bool _3451;\n            if (_3445)\n            {\n                _3451 = _3425 < 1.0;\n            }\n            else\n            {\n                _3451 = _3445;\n            }\n            bool _3457;\n            if (_3451)\n            {\n                _3457 = _3429 >= 0.0;\n            }\n            else\n            {\n                _3457 = _3451;\n            }\n            bool _3463;\n            if (_3457)\n            {\n                _3463 = _3429 < 1.0;\n            }\n            else\n            {\n                _3463 = _3457;\n            }\n            if (_3463)\n            {\n                vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3425, _3429) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3491 = _3488.w > 0.5;\n                bool _3507;\n                if (_3491)\n                {\n                    _3507 = abs(_3387 - _3488.x) <= (((0.00200000009499490261077880859375 * _3387) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3507 = _3491;\n                }\n                if (_3507)\n                {\n                    float _3513;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3513 = min(_3488.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3513 = _3488.y;\n                    }\n                    return _3513;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3550 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3553 = _3550.w > 0.5;\n    bool _3563;\n    if (_3553)\n    {\n        _3563 = abs(d - _3550.x) <= tol;\n    }\n    else\n    {\n        _3563 = _3553;\n    }\n    if (_3563)\n    {\n        best = min(best, mod(floor(_3550.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2783 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2790;\n    if (!_2783)\n    {\n        _2790 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2790 = _2783;\n    }\n    if (_2790)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2803 = fa_light_texel(param);\n    float _2804 = _2803.x;\n    if (_2804 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2813 = int(_2804 + 0.5);\n    int param_1 = _2813;\n    vec4 _2817 = fa_light_texel(param_1);\n    int param_2 = _2813 + 1;\n    vec4 _2822 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2825 = _2817.y;\n    if (_2825 > 0.0)\n    {\n        float _2842 = 1.0 - smoothstep(0.75 * _2825, _2825, length(world - fa_shadows[27].xyz));\n        fade = _2842;\n        if (_2842 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2817.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2866 = (_2813 + 2) + (face * 6);\n    int param_4 = _2866;\n    int param_5 = _2866 + 1;\n    int param_6 = _2866 + 3;\n    vec4 _2880 = fa_light_texel(param_6);\n    int param_7 = _2866 + 4;\n    vec4 _2885 = fa_light_texel(param_7);\n    int param_8 = _2866 + 5;\n    vec4 _2890 = fa_light_texel(param_8);\n    float _2902 = _2890.x * max(dot(_2880, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2907 = clamp(dot(n, l), 0.0, 1.0);\n    float _2930 = clamp(dot(n, _2880.xyz), -1.0, 1.0);\n    float _2949 = min(sqrt(1.0 - (_2930 * _2930)) / max(abs(dot(n, world - lpos)) / max(dot(_2880, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2952 = _2822.y;\n    float _2954;\n    if (_2952 > 0.0)\n    {\n        _2954 = _2952;\n    }\n    else\n    {\n        _2954 = 1.5 * _2902;\n    }\n    vec4 _2974 = vec4(world + (n * (_2954 * sqrt(1.0 - (_2907 * _2907)))), 1.0);\n    float _2978 = dot(_2880, _2974);\n    float _2981 = _2890.y;\n    if (_2978 < _2981)\n    {\n        return 1.0;\n    }\n    vec2 _2996 = vec2(dot(fa_light_texel(param_4), _2974), dot(fa_light_texel(param_5), _2974)) / vec2(_2978);\n    float _2998 = _2996.x;\n    bool _3001 = _2998 < _2885.x;\n    bool _3010;\n    if (!_3001)\n    {\n        _3010 = _2998 > _2885.z;\n    }\n    else\n    {\n        _3010 = _3001;\n    }\n    bool _3019;\n    if (!_3010)\n    {\n        _3019 = _2996.y < _2885.y;\n    }\n    else\n    {\n        _3019 = _3010;\n    }\n    bool _3028;\n    if (!_3019)\n    {\n        _3028 = _2996.y > _2885.w;\n    }\n    else\n    {\n        _3028 = _3019;\n    }\n    if (_3028)\n    {\n        return 1.0;\n    }\n    float _3034 = _2822.x;\n    float _3036;\n    if (_3034 > 0.0)\n    {\n        _3036 = _3034;\n    }\n    else\n    {\n        _3036 = 1.5 * _2902;\n    }\n    vec2 param_9 = _2996;\n    vec4 param_10 = _2885;\n    float param_11 = _2978 - (_3036 * (1.0 + (0.5 * _2949)));\n    float param_12 = _2902;\n    float param_13 = 1.0;\n    float param_14 = _2890.z * 0.25;\n    float param_15 = (_2902 * min(_2949, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2981, _2890.z);\n    int param_17 = int(_2817.z + 0.5);\n    float param_18 = _2817.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3581 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3587;\n    if (_3581)\n    {\n        _3587 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3587 = _3581;\n    }\n    bool _3593;\n    if (_3587)\n    {\n        _3593 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3593 = _3587;\n    }\n    if (_3593)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3605 = fa_light_texel(param);\n        float _3606 = _3605.z;\n        if (_3606 > 0.5)\n        {\n            float _3619 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3625 = ((0.00200000009499490261077880859375 * _3619) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3631 = vec4(world, 1.0);\n            float _3636 = dot(fa_mesh_fs_params[28], _3631);\n            if (_3636 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3653 = vec2(dot(fa_mesh_fs_params[26], _3631), dot(fa_mesh_fs_params[27], _3631)) / vec2(_3636);\n                float _3658 = (_3653.x * 0.5) + 0.5;\n                float _3662;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3662 = (_3653.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3662 = 0.5 - (_3653.y * 0.5);\n                }\n                bool _3678 = _3658 >= 0.0;\n                bool _3684;\n                if (_3678)\n                {\n                    _3684 = _3658 < 1.0;\n                }\n                else\n                {\n                    _3684 = _3678;\n                }\n                bool _3690;\n                if (_3684)\n                {\n                    _3690 = _3662 >= 0.0;\n                }\n                else\n                {\n                    _3690 = _3684;\n                }\n                bool _3696;\n                if (_3690)\n                {\n                    _3696 = _3662 < 1.0;\n                }\n                else\n                {\n                    _3696 = _3690;\n                }\n                if (_3696)\n                {\n                    ivec2 _3703 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3714 = clamp(ivec2(vec2(_3658, _3662) * fa_mesh_fs_params[24].zw), ivec2(0), _3703 - ivec2(1));\n                    float _3718;\n                    if (_3606 < 1.5)\n                    {\n                        _3718 = 1.0;\n                    }\n                    else\n                    {\n                        _3718 = (_3606 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3734 = texelFetch(fa_screen_tex_fa_shadow_smp, _3714, 0);\n                    bool _3737 = _3734.w > 0.5;\n                    bool _3747;\n                    if (_3737)\n                    {\n                        _3747 = abs(_3619 - _3734.x) <= _3625;\n                    }\n                    else\n                    {\n                        _3747 = _3737;\n                    }\n                    if (_3747)\n                    {\n                        best = mod(floor(_3734.z / _3718), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3714 + ivec2(-1);\n                        ivec2 param_2 = _3703;\n                        float param_3 = _3619;\n                        float param_4 = _3625;\n                        float param_5 = _3718;\n                        float param_6 = best;\n                        float _3773 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3773;\n                        ivec2 param_7 = _3714 + ivec2(0, -1);\n                        ivec2 param_8 = _3703;\n                        float param_9 = _3619;\n                        float param_10 = _3625;\n                        float param_11 = _3718;\n                        float param_12 = _3773;\n                        float _3788 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3788;\n                        ivec2 param_13 = _3714 + ivec2(1, -1);\n                        ivec2 param_14 = _3703;\n                        float param_15 = _3619;\n                        float param_16 = _3625;\n                        float param_17 = _3718;\n                        float param_18 = _3788;\n                        float _3803 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3803;\n                        ivec2 param_19 = _3714 + ivec2(-1, 0);\n                        ivec2 param_20 = _3703;\n                        float param_21 = _3619;\n                        float param_22 = _3625;\n                        float param_23 = _3718;\n                        float param_24 = _3803;\n                        float _3818 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3818;\n                        ivec2 param_25 = _3714 + ivec2(1, 0);\n                        ivec2 param_26 = _3703;\n                        float param_27 = _3619;\n                        float param_28 = _3625;\n                        float param_29 = _3718;\n                        float param_30 = _3818;\n                        float _3833 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3833;\n                        ivec2 param_31 = _3714 + ivec2(-1, 1);\n                        ivec2 param_32 = _3703;\n                        float param_33 = _3619;\n                        float param_34 = _3625;\n                        float param_35 = _3718;\n                        float param_36 = _3833;\n                        float _3848 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3848;\n                        ivec2 param_37 = _3714 + ivec2(0, 1);\n                        ivec2 param_38 = _3703;\n                        float param_39 = _3619;\n                        float param_40 = _3625;\n                        float param_41 = _3718;\n                        float param_42 = _3848;\n                        float _3863 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3863;\n                        ivec2 param_43 = _3714 + ivec2(1);\n                        ivec2 param_44 = _3703;\n                        float param_45 = _3619;\n                        float param_46 = _3625;\n                        float param_47 = _3718;\n                        float param_48 = _3863;\n                        float _3878 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3878;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3886;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3886 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3886 = best;\n                        }\n                        return _3886;\n                    }\n                }\n            }\n            float _3909;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3909 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3909 = 1.0;\n            }\n            return _3909;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5754 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5761;\n    if (!_5754)\n    {\n        _5761 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5761 = _5754;\n    }\n    if (_5761)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5774 = fa_light_texel(param);\n    float _5775 = _5774.y;\n    float len = _5775;\n    if (_5775 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5787 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5796 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5787);\n    if (_5796 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5802 = len;\n    float _5805 = min(_5802, 0.89999997615814208984375 * dist);\n    len = _5805;\n    float _5810 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5787);\n    float _5815 = _5810 + (0.5 * _5805);\n    vec3 _5821 = world + (gn * _5810);\n    float _5823 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5884;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5838 = (float(k) + _5823) * 0.083333335816860198974609375;\n        vec3 _5846 = _5821 + (l * (_5838 * len));\n        vec4 _5852 = vec4(_5846, 1.0);\n        float _5857 = dot(fa_mesh_fs_params[28], _5852);\n        if (_5857 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5875 = vec2(dot(fa_mesh_fs_params[26], _5852), dot(fa_mesh_fs_params[27], _5852)) / vec2(_5857);\n        float _5879 = _5875.x * 0.5;\n        float _5880 = _5879 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5884 = (_5875.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5884 = 0.5 - (_5875.y * 0.5);\n        }\n        bool _5900 = _5880 < 0.0;\n        bool _5907;\n        if (!_5900)\n        {\n            _5907 = _5880 >= 1.0;\n        }\n        else\n        {\n            _5907 = _5900;\n        }\n        bool _5914;\n        if (!_5907)\n        {\n            _5914 = _5884 < 0.0;\n        }\n        else\n        {\n            _5914 = _5907;\n        }\n        bool _5921;\n        if (!_5914)\n        {\n            _5921 = _5884 >= 1.0;\n        }\n        else\n        {\n            _5921 = _5914;\n        }\n        if (_5921)\n        {\n            break;\n        }\n        vec4 _5945 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5880, _5884) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5945.w < 0.5)\n        {\n            continue;\n        }\n        float _5963 = (dot(fa_mesh_fs_params[29].xyz, _5846) + fa_mesh_fs_params[29].w) - _5945.x;\n        if ((_5963 > _5810) && (_5963 < _5815))\n        {\n            occ = max(occ, (1.0 - (_5838 * _5838)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5880, 0.5 - _5879), min(_5884, 1.0 - _5884))));\n        }\n    }\n    return 1.0 - (occ * _5796);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6625 = fa_baked_keep(param);\n    if (_6625 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6651 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9919 = _6651.color;\n    float _9920 = _6651.attenuation;\n    float _9921 = _6651.shadow;\n    bool _6654 = _6651.type == 0;\n    if (_6654 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6651.direction;\n        float _6665 = fa_shadow_factor(param_5, param_6);\n        _9921 = _6665;\n        _9919 *= _6665;\n    }\n    else\n    {\n        bool _6676 = _6651.type != 0;\n        bool _6682;\n        if (_6676)\n        {\n            _6682 = _9920 > 0.0;\n        }\n        else\n        {\n            _6682 = _6676;\n        }\n        if (_6682)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6651.direction;\n            float _6701 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9921 = _6701;\n            _9919 *= _6701;\n        }\n    }\n    bool _6711 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6717;\n    if (_6711)\n    {\n        _6717 = _9920 > 0.0;\n    }\n    else\n    {\n        _6717 = _6711;\n    }\n    if (_6717)\n    {\n        float _6724;\n        if (_6654)\n        {\n            _6724 = 1000000000.0;\n        }\n        else\n        {\n            _6724 = _6651._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6651.direction;\n        float param_18 = _6724;\n        float _6742 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9921 *= _6742;\n        _9919 *= _6742;\n    }\n    float _6755 = _9920;\n    float _6756 = _6755 * _6625;\n    _9920 = _6756;\n    vec3 _6760 = _9919;\n    vec3 _6761 = _6760 * _6625;\n    _9919 = _6761;\n    return LightSample(_6651.direction, _6761, _6756, _9921, _6651._distance, _6651.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6795 = v - (n * dot(v, n));\n    vec3 t = _6795;\n    float _6799 = dot(_6795, _6795);\n    float l2 = _6799;\n    if (_6799 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6809;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6809 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6809 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6809;\n        l2 = dot(_6809, _6809);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7196;\n    if ((j == 0) || (j == 7))\n    {\n        _7196 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7206;\n        if ((j == 3) || (j == 4))\n        {\n            _7206 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7206 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7196 = _7206;\n    }\n    float _7227;\n    if ((j == 1) || (j == 2))\n    {\n        _7227 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7236;\n        if ((j == 5) || (j == 6))\n        {\n            _7236 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7236 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7227 = _7236;\n    }\n    return (pc + (ex * _7196)) + (ey * _7227);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6844 = dot(a, a);\n    float _6848 = dot(b, b);\n    if ((_6844 < 1.0000000195414813782625560981111e-24) || (_6848 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6862 = a * inversesqrt(_6844);\n    vec3 _6867 = b * inversesqrt(_6848);\n    float _6871 = dot(_6862, _6867);\n    float _6874 = abs(_6871);\n    float g = (((((((((((0.0416471660137176513671875 * _6874) - 0.1924748718738555908203125) * _6874) + 0.4179156124591827392578125) * _6874) - 0.616057217121124267578125) * _6874) + 0.777722418308258056640625) * _6874) - 0.999542415142059326171875) * _6874) + 1.570791721343994140625;\n    if (_6871 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6871 * _6871), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6862, _6867) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6931 = a.z > 0.0;\n    bool _6935 = b.z > 0.0;\n    if (_6931 && _6935)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6931 != _6935)\n        {\n            vec3 _6970 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6970.z = 0.0;\n            if (_6931)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6970;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6970;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6970;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6970;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7019 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7045 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7071 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7097 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7019;\n    vec3 param_1 = _7045;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7045;\n    vec3 param_7 = _7071;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7071;\n    vec3 param_13 = _7097;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7097;\n    vec3 param_19 = _7019;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7265 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7283;\n    for (int k = 0; k < (2 * _7265); k++)\n    {\n        bool _7280 = k >= _7265;\n        if (_7280)\n        {\n            _7283 = k - _7265;\n        }\n        else\n        {\n            _7283 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7265 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7329 = 2 * _7283;\n            int param_4 = _7329 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7329 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7329 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7366 = bvec4(_7280);\n        vec4 param_16 = vec4(_7366.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7366.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7366.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7366.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7377 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7280)\n        {\n            vec2 _10175 = sum;\n            _10175.y = _10175.y + _7377;\n            sum = _10175;\n        }\n        else\n        {\n            vec2 _10178 = sum;\n            _10178.x = _10178.x + _7377;\n            sum = _10178;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7401 = fa_light_base(param);\n    int param_1 = _7401;\n    int param_2 = _7401 + 1;\n    int param_3 = _7401 + 2;\n    int param_4 = _7401 + 4;\n    vec4 _7423 = fa_light_texel(param_4);\n    int param_5 = _7401 + 5;\n    vec4 _7428 = fa_light_texel(param_5);\n    int param_6 = _7401 + 6;\n    vec4 _7433 = fa_light_texel(param_6);\n    float _7434 = _7433.w;\n    vec3 _7439 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7441 = _7434 < 1.5;\n    bool _7448;\n    if (_7441)\n    {\n        _7448 = dot(normalize(fa_light_texel(param_3).xyz), _7439) >= 0.0;\n    }\n    else\n    {\n        _7448 = _7441;\n    }\n    if (_7448)\n    {\n        return vec3(0.0);\n    }\n    bool _7457 = (_7434 > 0.5) && _7441;\n    float _7461 = _7457 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7464 = _7423.xyz;\n    float _7466 = _7423.w;\n    vec3 _7472 = _7428.xyz;\n    float _7474 = _7428.w;\n    vec3 up = _7472 * (_7474 * _7461);\n    float _7480;\n    if (_7457)\n    {\n        _7480 = (3.1415927410125732421875 * _7466) * _7466;\n    }\n    else\n    {\n        _7480 = (4.0 * _7466) * _7474;\n    }\n    if (_7434 > 1.5)\n    {\n        vec3 _7506 = cross(_7464, -_7439);\n        vec3 perp = _7506;\n        float _7510 = dot(_7506, _7506);\n        vec3 _7513;\n        if (_7510 > 1.0000000133514319600180897396058e-10)\n        {\n            _7513 = perp * inversesqrt(_7510);\n        }\n        else\n        {\n            _7513 = _7472;\n        }\n        perp = _7513;\n        up = _7513 * _7474;\n    }\n    float _7534 = max(_7480, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7544 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7544;\n    vec3 param_10 = n;\n    vec3 param_11 = _7439;\n    vec3 param_12 = _7544;\n    vec3 param_13 = n;\n    vec3 param_14 = _7464 * (_7466 * _7461);\n    vec3 param_15 = _7544;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7575 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7575;\n    vec2 param_21 = _7575 + vec2(64.0, 0.0);\n    vec4 _7585 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7434;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7597 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7597.x) + (((f0 * _7585.x) + ((vec3(f90) - f0) * _7585.y)) * _7597.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7439, _7439)) + _7534) / _7534) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5491 = 1.0 / alpha;\n    return ((2.0 + _5491) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5491)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5526 = max(dot(L.nc, l), 0.0);\n    float _5532 = max(dot(L.nc, h), 0.0);\n    float _5541 = ((_5532 * _5532) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5541) * _5541)) * (0.5 / max(mix((2.0 * _5526) * L.coat_ndv, _5526 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5526)) * _5526;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7634;\n    if (L.sheen_on)\n    {\n        _7634 = L.sheen_scale;\n    }\n    else\n    {\n        _7634 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7634);\n    vec3 _7647 = normalize(l + v);\n    int param = li;\n    vec3 _7658 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7667 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7647), 0.0);\n        float param_3 = _7667;\n        float param_4 = ndv;\n        result += ((L.sheen * _7658) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7667)) * _7667) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7647;\n        float param_8 = max(dot(v, _7647), 0.0);\n        result += (_7658 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5394 = tdh / at;\n    float _5398 = bdh / ab;\n    float _5410 = ((_5394 * _5394) + (_5398 * _5398)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5410) * _5410);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5590 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5669 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5669) * _5669);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5590);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5590));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4793 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4796 = _4793.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4796 * _4796, exp2((-9.27999973297119140625) * ndv)) * _4796) + _4793.y)) + _4793.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4103;\n    if (lv == 0)\n    {\n        _4103 = 0.0;\n    }\n    else\n    {\n        _4103 = res + 2.0;\n    }\n    float _4113;\n    if (lv == 0)\n    {\n        _4113 = 0.0;\n    }\n    else\n    {\n        _4113 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4103, _4113)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4159;\n    if (res > 64.5)\n    {\n        _4159 = 5.0;\n    }\n    else\n    {\n        _4159 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4174 = clamp(rough, 0.0, 1.0) * (_4159 - 1.0);\n    int _4181 = int(min(floor(_4174), _4159 - 2.0));\n    float _4186 = _4174 - float(_4181);\n    vec3 param = d;\n    vec2 _4190 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4181;\n    vec2 param_4 = _4190;\n    vec3 _4200 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4186 < 0.00200000009499490261077880859375)\n    {\n        return _4200;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4181 + 1;\n    vec2 param_8 = _4190;\n    return mix(_4200, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4186));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4271 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4278 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4285 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4291 = dot(bx.xyz, d);\n    float _4295 = dot(by.xyz, d);\n    float _4299 = dot(bz.xyz, d);\n    float _4305;\n    if (_4291 > 9.9999999747524270787835121154785e-07)\n    {\n        _4305 = (1.0 - _4271) / _4291;\n    }\n    else\n    {\n        float _4319;\n        if (_4291 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4319 = ((-1.0) - _4271) / _4291;\n        }\n        else\n        {\n            _4319 = 1000000015047466219876688855040.0;\n        }\n        _4305 = _4319;\n    }\n    float tx = _4305;\n    float _4336;\n    if (_4295 > 9.9999999747524270787835121154785e-07)\n    {\n        _4336 = (1.0 - _4278) / _4295;\n    }\n    else\n    {\n        float _4349;\n        if (_4295 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4349 = ((-1.0) - _4278) / _4295;\n        }\n        else\n        {\n            _4349 = 1000000015047466219876688855040.0;\n        }\n        _4336 = _4349;\n    }\n    float ty = _4336;\n    float _4365;\n    if (_4299 > 9.9999999747524270787835121154785e-07)\n    {\n        _4365 = (1.0 - _4285) / _4299;\n    }\n    else\n    {\n        float _4378;\n        if (_4299 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4378 = ((-1.0) - _4285) / _4299;\n        }\n        else\n        {\n            _4378 = 1000000015047466219876688855040.0;\n        }\n        _4365 = _4378;\n    }\n    float _4390 = tx;\n    float _4393 = (_4390 > 0.0) ? _4390 : 1000000015047466219876688855040.0;\n    tx = _4393;\n    float _4394 = ty;\n    float _4397 = (_4394 > 0.0) ? _4394 : 1000000015047466219876688855040.0;\n    ty = _4397;\n    float _4407 = min(_4393, min(_4397, (_4365 > 0.0) ? _4365 : 1000000015047466219876688855040.0));\n    if (_4407 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4423 = (fa_world_pos + (d * _4407)) - posw.xyz;\n    vec3 _4428;\n    if (dot(_4423, _4423) > 1.0000000133514319600180897396058e-10)\n    {\n        _4428 = normalize(_4423);\n    }\n    else\n    {\n        _4428 = d;\n    }\n    return _4428;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4474 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4474 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4502 = rough * rough;\n            float _4533 = 0.60000002384185791015625 * _4502;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4502)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4533, 0.0500000007450580596923828125 + _4533, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4502 * 0.60000002384185791015625));\n        }\n        outc = base * _4474;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4592 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4592 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4624 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4624 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5271;\n        if (L.aniso >= 0.0)\n        {\n            _5271 = L.b;\n        }\n        else\n        {\n            _5271 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5271, v), _5271), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5307 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5307.x) + (vec3(L.f90) * _5307.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5365 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5365.x) + _5365.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4835 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4835.x) + vec3(_4835.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6067 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6071 = fa_xm_origin(param_1);\n    vec2 _6077 = (uv * _6067) - vec2(0.5);\n    vec2 _6080 = fract(_6077);\n    vec2 _6083 = floor(_6077);\n    vec2 param_2 = _6067;\n    vec2 param_3 = _6071;\n    vec2 param_4 = _6083;\n    vec2 param_5 = _6067;\n    vec2 param_6 = _6071;\n    vec2 param_7 = _6083 + vec2(1.0, 0.0);\n    vec2 param_8 = _6067;\n    vec2 param_9 = _6071;\n    vec2 param_10 = _6083 + vec2(0.0, 1.0);\n    vec2 param_11 = _6067;\n    vec2 param_12 = _6071;\n    vec2 param_13 = _6083 + vec2(1.0);\n    vec3 _6125 = vec3(_6080.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6125), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6125), vec3(_6080.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6144 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6148 = clamp(lod, 0.0, _6144);\n    int _6152 = int(floor(_6148));\n    int param = _6152;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6162 = float(_6152);\n    float _6163 = _6148 - _6162;\n    bool _6165 = _6163 > 0.001000000047497451305389404296875;\n    bool _6172;\n    if (_6165)\n    {\n        _6172 = _6162 < _6144;\n    }\n    else\n    {\n        _6172 = _6165;\n    }\n    if (_6172)\n    {\n        int param_2 = _6152 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6163));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6198 = fa_env_brdf(param, param_1);\n    vec3 _6222 = ((vec3(1.0) - clamp((f0 * _6198.x) + (vec3(f90) * _6198.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6222;\n    float _6228 = max(s.thickness, 0.0);\n    bool _6233 = _6228 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6233)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6228);\n    }\n    bool _6258 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6264;\n    if (_6258)\n    {\n        _6264 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6264 = _6258;\n    }\n    bool _6271;\n    if (!_6264)\n    {\n        _6271 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6271 = _6264;\n    }\n    if (_6271)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6286 = vec4(fa_world_pos, 1.0);\n    float _6291 = dot(fa_mesh_fs_params[28], _6286);\n    vec2 uv0 = vec2(0.5);\n    if (_6291 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6309 = vec2(dot(fa_mesh_fs_params[26], _6286), dot(fa_mesh_fs_params[27], _6286)) / vec2(_6291);\n        float _6317;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6317 = (_6309.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6317 = 0.5 - (_6309.y * 0.5);\n        }\n        uv0 = vec2((_6309.x * 0.5) + 0.5, _6317);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6338 = fa_xm_size(param_2);\n        vec2 _6346 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6338);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6346), 0).w > 0.5)\n        {\n            int _6366 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6389 = abs(dx) > _6366;\n                    bool _6397;\n                    if (!_6389)\n                    {\n                        _6397 = abs(dy) > _6366;\n                    }\n                    else\n                    {\n                        _6397 = _6389;\n                    }\n                    if (_6397)\n                    {\n                        continue;\n                    }\n                    vec4 _6418 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6346 + vec2(float(dx), float(dy)), vec2(0.0), _6338 - vec2(1.0))), 0);\n                    if (_6418.w > 0.5)\n                    {\n                        acc += _6418.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6222 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6233)\n    {\n        vec4 _6466 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6228), 1.0);\n        float _6471 = dot(fa_mesh_fs_params[28], _6466);\n        uv = vec2(0.5);\n        if (_6471 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6488 = vec2(dot(fa_mesh_fs_params[26], _6466), dot(fa_mesh_fs_params[27], _6466)) / vec2(_6471);\n            float _6496;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6496 = (_6488.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6496 = 0.5 - (_6488.y * 0.5);\n            }\n            uv = vec2((_6488.x * 0.5) + 0.5, _6496);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3290 = int(fa_shadows[25].x + 0.5);\n    float _3300 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3305 = _3290 > 0;\n    bool _3314;\n    if (_3305)\n    {\n        int param = _3290 - 1;\n        _3314 = _3300 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3314 = _3305;\n    }\n    if (_3314)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3320 = _3290 > 1;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3300 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3333 = _3290 > 2;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3300 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3346 = _3290 > 3;\n        bool _3353;\n        if (_3346)\n        {\n            _3353 = _3300 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3353 = _3346;\n        }\n        if (_3353)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9578 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9578 = -_9578;\n    }\n    vec3 _8871 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n    Surface _8879 = fa_standard_surface(param_1);\n    vec3 _9609 = _8879.albedo;\n    float _9610 = _8879.alpha;\n    vec3 _9611 = _8879.normal;\n    float _9612 = _8879.metallic;\n    float _9613 = _8879.roughness;\n    float _9614 = _8879.occlusion;\n    vec3 _9615 = _8879.emission;\n    float _9616 = _8879.clearcoat;\n    float _9617 = _8879.clearcoat_roughness;\n    vec3 _9618 = _8879.sheen_color;\n    float _9619 = _8879.sheen_roughness;\n    float _9620 = _8879.anisotropy;\n    float _9621 = _8879.anisotropy_rotation;\n    float _9622 = _8879.specular;\n    float _9623 = _8879.ior;\n    vec3 _9624 = _8879.specular_color;\n    float _9625 = _8879.transmission;\n    float _9626 = _8879.thickness;\n    vec3 _9627 = _8879.attenuation_color;\n    float _9628 = _8879.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n    Surface param_3 = _8879;\n    surface(param_2, param_3);\n    _9609 = param_3.albedo;\n    _9610 = param_3.alpha;\n    _9611 = param_3.normal;\n    _9612 = param_3.metallic;\n    _9613 = param_3.roughness;\n    _9614 = param_3.occlusion;\n    _9615 = param_3.emission;\n    _9616 = param_3.clearcoat;\n    _9617 = param_3.clearcoat_roughness;\n    _9618 = param_3.sheen_color;\n    _9619 = param_3.sheen_roughness;\n    _9620 = param_3.anisotropy;\n    _9621 = param_3.anisotropy_rotation;\n    _9622 = param_3.specular;\n    _9623 = param_3.ior;\n    _9624 = param_3.specular_color;\n    _9625 = param_3.transmission;\n    _9626 = param_3.thickness;\n    _9627 = param_3.attenuation_color;\n    _9628 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9578;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9609 = param_6;\n    _9611 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9609;\n    }\n    else\n    {\n        vec3 _8919 = normalize(_9611);\n        float _8926 = clamp(_9612, 0.0, 1.0);\n        float _8930 = clamp(_9613, 0.0500000007450580596923828125, 1.0);\n        float _8934 = _8930 * _8930;\n        float _8938 = _8934 * _8934;\n        float _8943 = max(dot(_8919, _8871), 9.9999997473787516355514526367188e-05);\n        float _8949 = 1.0 - _8926;\n        float _8950 = clamp(_9625, 0.0, 1.0) * _8949;\n        vec3 _8959 = (_9609 * _8949) * (1.0 - _8950);\n        vec3 _8966 = mix(vec3(0.039999999105930328369140625), _9609, vec3(_8926));\n        vec3 f0 = _8966;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9578, fa_world_tangent, fa_uv, fa_vertex_color, _8871, gl_FrontFacing);\n        Surface param_9 = Surface(_9609, _9610, _9611, _9612, _9613, _9614, _9615, _9616, _9617, _9618, _9619, _9620, _9621, _9622, _9623, _9624, _9625, _9626, _9627, _9628);\n        vec3 param_10 = _8919;\n        vec3 param_11 = _8871;\n        float param_12 = _8926;\n        float param_13 = _8930;\n        vec3 param_14 = _8966;\n        FaLayers _8982 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8919;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8959) * _9614;\n        if (_8982.on)\n        {\n            lit *= _8982.base_scale;\n        }\n        int _9004 = fa_cl_ndir + fa_cl_local;\n        float _9069;\n        for (int ln = 0; ln < _9004; ln++)\n        {\n            int param_16 = ln;\n            int _9017 = fa_cl_light(param_16);\n            int param_17 = _9017;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9017;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9578;\n            LightSample _9033 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9041 = max(dot(_8919, _9033.direction), 0.0);\n            float _9047 = _9033.attenuation * _9033.shadow;\n            vec3 _9052 = normalize(_9033.direction + _8871);\n            float _9057 = max(dot(_8919, _9052), 0.0);\n            float _9062 = max(dot(_8871, _9052), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8982.on)\n                {\n                    _9069 = _8982.f90;\n                }\n                else\n                {\n                    _9069 = 1.0;\n                }\n                int param_21 = _9017;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8919;\n                vec3 param_24 = _8871;\n                vec3 param_25 = _8959;\n                vec3 param_26 = f0;\n                float param_27 = _9069;\n                float param_28 = _8930;\n                float param_29 = _8943;\n                float param_30 = _9047;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8982.on)\n                {\n                    FaLayers param_31 = _8982;\n                    vec3 param_32 = area;\n                    int param_33 = _9017;\n                    vec3 param_34 = _8919;\n                    vec3 param_35 = _8871;\n                    vec3 param_36 = _9033.direction;\n                    float param_37 = _8943;\n                    float param_38 = _9047;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8982.on)\n                {\n                    FaLayers param_39 = _8982;\n                    vec3 param_40 = _8959;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8919;\n                    vec3 param_43 = _8871;\n                    vec3 param_44 = _9033.direction;\n                    vec3 param_45 = _9052;\n                    float param_46 = _9041;\n                    float param_47 = _8943;\n                    float param_48 = _9057;\n                    float param_49 = _9062;\n                    float param_50 = _8934;\n                    float param_51 = _8938;\n                    int param_52 = _9017;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9047));\n                }\n                else\n                {\n                    float _9171 = ((_9057 * _9057) * (_8938 - 1.0)) + 1.0;\n                    int param_53 = _9017;\n                    lit += (((_8959 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9062, 5.0))) * (((_8938 / ((3.1415927410125732421875 * _9171) * _9171)) * (0.5 / max(mix((2.0 * _9041) * _8943, _9041 + _8943, _8934), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9041))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9041 * _9047));\n                }\n            }\n        }\n        if (_8982.on)\n        {\n            FaLayers param_54 = _8982;\n            vec3 param_55 = _8919;\n            vec3 param_56 = _8871;\n            vec3 param_57 = f0;\n            float param_58 = _8930;\n            float param_59 = _9614;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8919;\n            vec3 param_61 = _8871;\n            vec3 param_62 = f0;\n            float param_63 = _8930;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9614);\n        }\n        if (_8950 > 0.0)\n        {\n            float _9269;\n            if (_8982.on)\n            {\n                _9269 = _8982.f90;\n            }\n            else\n            {\n                _9269 = 1.0;\n            }\n            float _9277;\n            if (_8982.on)\n            {\n                _9277 = _8982.base_scale;\n            }\n            else\n            {\n                _9277 = 1.0;\n            }\n            Surface param_64 = Surface(_9609, _9610, _9611, _9612, _9613, _9614, _9615, _9616, _9617, _9618, _9619, _9620, _9621, _9622, _9623, _9624, _9625, _9626, _9627, _9628);\n            vec3 param_65 = _8919;\n            vec3 param_66 = _8871;\n            float param_67 = _8930;\n            vec3 param_68 = f0;\n            float param_69 = _9269;\n            float param_70 = _9277;\n            float param_71 = _8950;\n            float param_72 = fa_tr_blend;\n            vec3 _9301 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9301;\n        }\n        result = lit;\n    }\n    vec3 _9308 = result;\n    vec3 _9309 = _9308 + _9615;\n    result = _9309;\n    vec3 param_73 = _9309;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9318 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9325;\n    if (!_9318)\n    {\n        _9325 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9325 = _9318;\n    }\n    if (_9325)\n    {\n        vec3 _9334 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9340 = dot(_9334, fa_mesh_fs_params[9].xyz);\n        bool _9344 = fa_mesh_fs_params[9].w > 0.5;\n        float _9345;\n        if (_9344)\n        {\n            _9345 = _9340;\n        }\n        else\n        {\n            _9345 = length(_9334);\n        }\n        float _9357 = _9345 - fa_mesh_fs_params[8].x;\n        if (_9357 > 0.0)\n        {\n            float _9366 = fa_mesh_fs_params[7].w * _9357;\n            float tau = _9366 * _9366;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9382;\n                if (_9344)\n                {\n                    _9382 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9340);\n                }\n                else\n                {\n                    _9382 = fa_mesh_fs_params[0].y;\n                }\n                float _9403 = mix(_9382, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9345, 0.0, 1.0));\n                float _9407 = fa_world_pos.y - _9403;\n                float _9412 = _9403 - fa_mesh_fs_params[8].z;\n                float _9417 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9420 = _9412 <= 0.0;\n                bool _9421 = !_9420;\n                bool _9427;\n                if (_9421)\n                {\n                    _9427 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9427 = _9420;\n                }\n                float _9428;\n                if (_9427)\n                {\n                    _9428 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9428 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9412, 80.0));\n                }\n                bool _9455;\n                if (_9421)\n                {\n                    _9455 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9455 = _9420;\n                }\n                float _9456;\n                if (_9455)\n                {\n                    _9456 = fa_mesh_fs_params[8].y * _9412;\n                }\n                else\n                {\n                    _9456 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9412, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9481 = _9417 <= 0.0;\n                bool _9488;\n                if (!_9481)\n                {\n                    _9488 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9488 = _9481;\n                }\n                float _9489;\n                if (_9488)\n                {\n                    _9489 = fa_mesh_fs_params[8].y * _9417;\n                }\n                else\n                {\n                    _9489 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9417, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9516;\n                if (abs(_9407) < 0.001000000047497451305389404296875)\n                {\n                    _9516 = _9428;\n                }\n                else\n                {\n                    _9516 = (_9489 - _9456) / _9407;\n                }\n                tau += (_9357 * max(_9516, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9552 = 1.0 - fa_tr_blend;\n        result /= vec3(_9552);\n        _9610 *= _9552;\n    }\n    fa_frag_color = vec4(result, _9610);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_669",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2331",
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
              "name": "fa_probe_atlas",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _144 = cross(model[1].xyz, model[2].xyz);\n    float _147 = (dot(model[0].xyz, _144) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_144 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _147, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _147), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _82 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _97;\n    if (!_82)\n    {\n        _97 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _97 = _82;\n    }\n    if (_97)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _221;\n    if (has_prev)\n    {\n        _221 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _221 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _244 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _251 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_244 * _251).z;\n    fa_pre_r0 = vec3(_244[0].x, _244[1].x, _244[2].x);\n    fa_pre_r1 = vec3(_244[0].y, _244[1].y, _244[2].y);\n    fa_pre_r2 = vec3(_244[0].z, _244[1].z, _244[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _251;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_221)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _251).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = false;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    vec4 _262 = (_859 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = fa_mesh_fs_params[20].x;\n    float _820 = fa_mesh_fs_params[20].y;\n    float _823 = fa_mesh_fs_params[20].z;\n    float _822 = fa_mesh_fs_params[21].w;\n    float _825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _814, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _819, _820, fa_mesh_fs_params[21].xyz, _822, _823, fa_mesh_fs_params[20].w, _825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_56",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_217",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_382",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _236 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_236 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_236 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_236 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _149 = cross(model[1].xyz, model[2].xyz);\n    float _152 = (dot(model[0].xyz, _149) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_149 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _152, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _152), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _87 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _102;\n    if (!_87)\n    {\n        _102 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _102 = _87;\n    }\n    if (_102)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nmat4 fa_prev_model()\n{\n    return mat4(vec4(1.0, 0.0, 0.0, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _332;\n    if (has_prev)\n    {\n        _332 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _332 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _355 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _362 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_355 * _362).z;\n    fa_pre_r0 = vec3(_355[0].x, _355[1].x, _355[2].x);\n    fa_pre_r1 = vec3(_355[0].y, _355[1].y, _355[2].y);\n    fa_pre_r2 = vec3(_355[0].z, _355[1].z, _355[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _362;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_332)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _362).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = false;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _247 = fa_tex_fix(param_2, param_3);\n    vec4 _859 = base_t;\n    _859.x = _247.x;\n    _859.y = _247.y;\n    _859.z = _247.z;\n    base_t = _859;\n    vec4 _262 = (_859 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _814 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _297 = fa_tex_fix(param_6, param_7);\n        vec3 _301 = (_297 * 2.0) - vec3(1.0);\n        vec2 _306 = _301.xy * fa_mesh_fs_params[6].x;\n        vec3 _867 = _301;\n        _867.x = _306.x;\n        _867.y = _306.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _867;\n        _814 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _337 = fa_tex_fix(param_12, param_13);\n    vec4 _870 = mrt;\n    _870.x = _337.x;\n    _870.y = _337.y;\n    _870.z = _337.z;\n    mrt = _870;\n    vec4 _369 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _369.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _381 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _413 = fa_tex_fix(param_20, param_21);\n    float _819 = fa_mesh_fs_params[20].x;\n    float _820 = fa_mesh_fs_params[20].y;\n    float _823 = fa_mesh_fs_params[20].z;\n    float _822 = fa_mesh_fs_params[21].w;\n    float _825 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _819 *= _381.y;\n            _820 *= _381.z;\n            _822 *= _369.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _823 *= mrt.x;\n            _825 *= mrt.w;\n        }\n    }\n    return Surface(_262.xyz, _262.w, _814, clamp(fa_mesh_fs_params[5].x * _337.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _337.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_381.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _413), _819, _820, fa_mesh_fs_params[21].xyz, _822, _823, fa_mesh_fs_params[20].w, _825, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _709 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _709 = -_709;\n    }\n    vec3 _565 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _709, fa_world_tangent, fa_uv, fa_vertex_color, _565, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _580 = normalize(param_2.normal);\n    vec3 _595 = normalize(vec3(dot(fa_pre_r0, _580), dot(fa_pre_r1, _580), dot(fa_pre_r2, _580)));\n    float _607 = _595.z;\n    vec2 e = _595.xy / vec2((abs(_595.x) + abs(_595.y)) + abs(_607));\n    if (_607 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _651 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _658;\n    if (_651)\n    {\n        _658 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _658 = _651;\n    }\n    if (_658)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_61",
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
            "inst_name": "_245",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_328",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_493",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_232",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
