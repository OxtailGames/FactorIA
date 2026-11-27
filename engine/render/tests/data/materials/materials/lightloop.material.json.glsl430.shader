{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4472[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1416 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1423;\n    if (!_1416)\n    {\n        _1423 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1423 = _1416;\n    }\n    bool _1431;\n    if (!_1423)\n    {\n        _1431 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1431 = _1423;\n    }\n    bool _1438;\n    if (!_1431)\n    {\n        _1438 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1438 = _1431;\n    }\n    bool _1445;\n    if (!_1438)\n    {\n        _1445 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1445 = _1438;\n    }\n    if (_1445)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1455 = vec4(world_pos, 1.0);\n    float _1461 = dot(fa_mesh_fs_params[16], _1455);\n    if (!(_1461 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1483 = vec2(dot(fa_mesh_fs_params[14], _1455), dot(fa_mesh_fs_params[15], _1455)) / vec2(_1461);\n    int _1487 = int(fa_mesh_fs_params[18].x);\n    int _1491 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1491) + clamp(int(floor(((_1483.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1491 - 1)) * _1487)) + clamp(int(floor(((_1483.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1487 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1567 = fa_cluster_texel(param);\n    return ivec2(int(_1567.x), int(_1567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5298 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5301 = fwidth(_5298);\n    bool _5304 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5311;\n    if (!_5304)\n    {\n        _5311 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5311 = _5304;\n    }\n    if (_5311)\n    {\n        fa_rt_slope = min(1.5 * _5301, 0.100000001490116119384765625 * _5298);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5327 = fa_cluster_lookup(param);\n    fa_cl_slot = _5327.x;\n    fa_cl_local = _5327.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5703 = fa_linear_to_srgb(param);\n        c = _5703;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5711 = fa_srgb_to_linear(param_1);\n            c = _5711;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _368;\n    if (i.front_facing)\n    {\n        _368 = i.world_normal;\n    }\n    else\n    {\n        _368 = -i.world_normal;\n    }\n    vec3 _392 = normalize(i.world_tangent.xyz - (_368 * dot(_368, i.world_tangent.xyz)));\n    vec3 _420 = normalize(((_392 * m.x) + ((cross(_368, _392) * i.world_tangent.w) * m.y)) + (_368 * m.z));\n    vec3 _423;\n    if (i.front_facing)\n    {\n        _423 = _420;\n    }\n    else\n    {\n        _423 = -_420;\n    }\n    return _423;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5743 = fa_tex_fix(param_2, param_3);\n    vec4 _6914 = base_t;\n    _6914.x = _5743.x;\n    _6914.y = _5743.y;\n    _6914.z = _5743.z;\n    base_t = _6914;\n    vec4 _5757 = (_6914 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6696 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5791 = fa_tex_fix(param_6, param_7);\n        vec3 _5794 = (_5791 * 2.0) - vec3(1.0);\n        vec2 _5799 = _5794.xy * fa_mesh_fs_params[6].x;\n        vec3 _6922 = _5794;\n        _6922.x = _5799.x;\n        _6922.y = _5799.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6922;\n        _6696 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5829 = fa_tex_fix(param_12, param_13);\n    vec4 _6925 = mrt;\n    _6925.x = _5829.x;\n    _6925.y = _5829.y;\n    _6925.z = _5829.z;\n    mrt = _6925;\n    vec4 _5859 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5859.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5870 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5902 = fa_tex_fix(param_20, param_21);\n    float _6701 = fa_mesh_fs_params[20].x;\n    float _6702 = fa_mesh_fs_params[20].y;\n    float _6705 = fa_mesh_fs_params[20].z;\n    float _6704 = fa_mesh_fs_params[21].w;\n    float _6707 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6701 *= _5870.y;\n            _6702 *= _5870.z;\n            _6704 *= _5859.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6705 *= mrt.x;\n            _6707 *= mrt.w;\n        }\n    }\n    return Surface(_5757.xyz, _5757.w, _6696, clamp(fa_mesh_fs_params[5].x * _5829.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5870.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5902), _6701, _6702, fa_mesh_fs_params[21].xyz, _6704, _6705, fa_mesh_fs_params[20].w, _6707, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1647 = rect.zw - rect.xy;\n    vec2 _1651 = _1647 * atlas;\n    vec2 _1655 = ddx * _1651;\n    vec2 _1659 = ddy * _1651;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1647), clamp(0.5 * log2(max(max(dot(_1655, _1655), dot(_1659, _1659)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1692 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1699;\n    if (!_1692)\n    {\n        _1699 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1699 = _1692;\n    }\n    if (_1699)\n    {\n        return;\n    }\n    vec3 _1705 = dFdx(world_pos);\n    vec3 _1708 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1712 = fa_cluster_texel(param);\n    int _1716 = int(_1712.w);\n    if (_1716 < 1)\n    {\n        return;\n    }\n    int _1726 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1726;\n    vec4 _1730 = fa_light_texel(param_1);\n    vec2 _1733 = _1730.yz;\n    int _1737 = int(_1730.w);\n    int param_2 = _1726 + 1;\n    vec4 _1742 = fa_light_texel(param_2);\n    float _1743 = _1742.x;\n    int _1749 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1753 = int(_1712.z);\n    vec3 _2018;\n    for (int k = 0; k < _1716; k++)\n    {\n        int _1766 = _1753 + k;\n        int param_3 = _1737 + (_1766 >> 2);\n        int _1783 = (_1726 + 2) + (int(fa_light_texel(param_3)[_1766 & 3]) * 7);\n        int param_4 = _1783 + 6;\n        vec4 _1788 = fa_light_texel(param_4);\n        if (((int(_1788.w + 0.5) >> _1749) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1783;\n        vec4 _1803 = fa_light_texel(param_5);\n        int param_6 = _1783 + 1;\n        vec4 _1808 = fa_light_texel(param_6);\n        int param_7 = _1783 + 2;\n        vec4 _1813 = fa_light_texel(param_7);\n        vec3 _1816 = _1803.xyz;\n        float _1821 = dot(_1816, world_pos) + _1803.w;\n        vec3 _1823 = _1808.xyz;\n        float _1828 = dot(_1823, world_pos) + _1808.w;\n        vec3 _1830 = _1813.xyz;\n        float _1835 = dot(_1830, world_pos) + _1813.w;\n        bool _1840 = abs(_1821) > 0.5;\n        bool _1848;\n        if (!_1840)\n        {\n            _1848 = abs(_1828) > 0.5;\n        }\n        else\n        {\n            _1848 = _1840;\n        }\n        bool _1856;\n        if (!_1848)\n        {\n            _1856 = abs(_1835) > 0.5;\n        }\n        else\n        {\n            _1856 = _1848;\n        }\n        if (_1856)\n        {\n            continue;\n        }\n        float _1871 = clamp(dot(geo_normal, normalize(_1830)) * _1788.z, 0.0, 1.0);\n        if (_1871 <= 0.0)\n        {\n            continue;\n        }\n        float _1891 = (clamp((0.5 - abs(_1835)) * 10.0, 0.0, 1.0) * _1871) * _1788.x;\n        vec2 _1899 = vec2(_1821 + 0.5, 0.5 - _1828);\n        vec2 _1909 = vec2(dot(_1816, _1705), dot(_1823, _1705));\n        vec2 _1919 = vec2(dot(_1816, _1708), dot(_1823, _1708));\n        int param_8 = _1783 + 5;\n        vec4 _1924 = fa_light_texel(param_8);\n        int param_9 = _1783 + 3;\n        vec4 _1929 = fa_light_texel(param_9);\n        int param_10 = _1783 + 4;\n        vec4 _1934 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1924.xyz;\n        bool _1944 = _1929.z > _1929.x;\n        if (_1944)\n        {\n            vec4 param_11 = _1929;\n            vec2 param_12 = _1899;\n            vec2 param_13 = _1733;\n            vec2 param_14 = _1909;\n            vec2 param_15 = _1919;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1743 > 0.5) && (_1743 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1970 = fa_dc_to_linear(param_16);\n                vec4 _6784 = tx;\n                _6784.x = _1970.x;\n                _6784.y = _1970.y;\n                _6784.z = _1970.z;\n                tx = _6784;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1891 * tex_a) * _1924.w, 0.0, 1.0)));\n        if (_1934.z > _1934.x)\n        {\n            vec4 param_17 = _1934;\n            vec2 param_18 = _1899;\n            vec2 param_19 = _1733;\n            vec2 param_20 = _1909;\n            vec2 param_21 = _1919;\n            vec4 _2014 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1743 > 1.5)\n            {\n                vec3 param_22 = _2014.xyz;\n                vec3 _2024 = fa_dc_to_srgb(param_22);\n                _2018 = _2024;\n            }\n            else\n            {\n                _2018 = _2014.xyz;\n            }\n            vec3 _2033 = (_2018 * 2.0) - vec3(1.0);\n            vec2 _2038 = _2033.xy * _1788.y;\n            vec3 _2060 = (normalize(_1816) * _2038.x) + (normalize(_1823) * _2038.y);\n            vec3 _2063 = normalize(normal);\n            normal = normalize(mix(_2063, normalize((_2063 * max(_2033.z, 0.0500000007450580596923828125)) + (_2060 - (_2063 * dot(_2063, _2060)))), vec3(clamp(_1891 * (_1944 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5268;\n    if (fa_lm.z > 0.5)\n    {\n        _5268 = 0.0;\n    }\n    else\n    {\n        _5268 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5279 = _5268 < 1.0;\n    bool _5285;\n    if (_5279)\n    {\n        int param = li;\n        _5285 = fa_light_baked(param);\n    }\n    else\n    {\n        _5285 = _5279;\n    }\n    return _5285 ? _5268 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _665 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _678 = (c - (ru * hx)) - p;\n        vec3 _684 = ru * (2.0 * hx);\n        float _690 = max(dot(_684, _684), 9.9999999392252902907785028219223e-09);\n        float _694 = dot(_678, _684);\n        float t = clamp((-_694) / _690, 0.0, 1.0);\n        if (_665)\n        {\n            float _709 = dot(r, _684);\n            float _715 = _690 - (_709 * _709);\n            if (abs(_715) > (9.9999997473787516355514526367188e-06 * _690))\n            {\n                t = clamp(((dot(r, _678) * _709) - _694) / _715, 0.0, 1.0);\n            }\n        }\n        return (p + _678) + (_684 * t);\n    }\n    vec3 q = p;\n    float _747 = dot(r, axis);\n    bool _755;\n    if (_665)\n    {\n        _755 = abs(_747) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _755 = _665;\n    }\n    if (_755)\n    {\n        float _765 = dot(c - p, axis) / _747;\n        if (_765 > 0.0)\n        {\n            q = p + (r * _765);\n        }\n    }\n    vec3 _778 = q - c;\n    vec2 xy = vec2(dot(_778, ru), dot(_778, uu));\n    if (shape > 0.5)\n    {\n        float _793 = length(xy);\n        if (_793 > hx)\n        {\n            xy *= (hx / _793);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _585 = dot(d, right);\n    float _589 = dot(d, up);\n    float _600;\n    if (((_585 * _585) + (_589 * _589)) > 1.0000000133514319600180897396058e-10)\n    {\n        _600 = atan(_589, _585) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _600 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_600 - floor(_600)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _435 = abs(d);\n    float _437 = _435.x;\n    float _439 = _435.y;\n    bool _440 = _437 >= _439;\n    bool _448;\n    if (_440)\n    {\n        _448 = _437 >= _435.z;\n    }\n    else\n    {\n        _448 = _440;\n    }\n    int _449;\n    if (_448)\n    {\n        _449 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _463;\n        if (_439 >= _435.z)\n        {\n            _463 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _463 = (d.z > 0.0) ? 4 : 5;\n        }\n        _449 = _463;\n    }\n    return _449;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _831 = fa_light_base(param);\n    bool _835 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _831;\n    vec4 _839 = fa_light_texel(param_1);\n    int param_2 = _831 + 1;\n    vec4 _844 = fa_light_texel(param_2);\n    float _847 = _844.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _859 = _835 && (_847 > 2.5);\n    fa_light_is_area = _859;\n    bool _861 = _847 < 0.5;\n    vec3 l;\n    if (_861)\n    {\n        l = normalize(_839.xyz);\n        if (_835)\n        {\n            int param_3 = _831 + 6;\n            vec4 _875 = fa_light_texel(param_3);\n            if (_875.z > 0.5)\n            {\n                int param_4 = _831 + 4;\n                vec4 _885 = fa_light_texel(param_4);\n                int param_5 = _831 + 5;\n                vec4 _890 = fa_light_texel(param_5);\n                vec2 param_6 = _875.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _885.xyz) * _885.w, (-dot(world_pos, _890.xyz)) * _890.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _920 = _839.xyz;\n        vec3 _922 = _920 - world_pos;\n        vec3 to_light = _922;\n        float _925 = length(_922);\n        float reach = _925;\n        bool front = true;\n        if (_859)\n        {\n            int param_8 = _831 + 7;\n            reach = max(_925 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _831 + 4;\n            vec4 _949 = fa_light_texel(param_9);\n            int param_10 = _831 + 5;\n            vec4 _954 = fa_light_texel(param_10);\n            int param_11 = _831 + 6;\n            vec4 _959 = fa_light_texel(param_11);\n            float _960 = _959.w;\n            int param_12 = _831 + 2;\n            vec3 _967 = normalize(fa_light_texel(param_12).xyz);\n            bool _969 = _960 > 1.5;\n            bool _977;\n            if (!_969)\n            {\n                _977 = dot(_967, to_light) < 0.0;\n            }\n            else\n            {\n                _977 = _969;\n            }\n            front = _977;\n            vec3 r = vec3(0.0);\n            vec3 _986 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _990 = dot(n, n) > 0.5;\n            bool _998;\n            if (_990)\n            {\n                _998 = dot(_986, _986) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            if (_998)\n            {\n                r = reflect(-normalize(_986), normalize(n));\n            }\n            vec3 param_13 = _920;\n            vec3 param_14 = _967;\n            vec3 param_15 = _949.xyz;\n            vec3 param_16 = _954.xyz;\n            float param_17 = _949.w;\n            float param_18 = _954.w;\n            float param_19 = _960;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1034 = length(to_light);\n        dist = _1034;\n        l = to_light / vec3(max(_1034, 9.9999997473787516355514526367188e-05));\n        float _1048 = reach / max(_839.w, 0.001000000047497451305389404296875);\n        float _1054 = clamp(1.0 - (_1048 * _1048), 0.0, 1.0);\n        float _1056;\n        if (front)\n        {\n            _1056 = _1054 * _1054;\n        }\n        else\n        {\n            _1056 = 0.0;\n        }\n        atten = _1056;\n        bool _1067 = _847 < 2.5;\n        if ((_847 > 1.5) && _1067)\n        {\n            int param_22 = _831 + 2;\n            vec4 _1075 = fa_light_texel(param_22);\n            float _1085 = _1075.w;\n            int param_23 = _831 + 3;\n            vec4 _1090 = fa_light_texel(param_23);\n            float _1091 = _1090.x;\n            float cos_inner = _1091;\n            if (_1091 > 1.5)\n            {\n                cos_inner = mix(_1085, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1085, cos_inner, dot(-l, normalize(_1075.xyz)));\n        }\n        if (_835 && (_847 < 1.5))\n        {\n            int param_24 = _831 + 6;\n            vec4 _1115 = fa_light_texel(param_24);\n            if (_1115.z > 0.5)\n            {\n                vec3 _1123 = -to_light;\n                int param_25 = _831 + 4;\n                int param_26 = _831 + 5;\n                vec3 _1137 = fa_light_texel(param_25).xyz;\n                vec3 _1141 = fa_light_texel(param_26).xyz;\n                vec3 _1150 = vec3(dot(_1123, _1137), dot(_1123, _1141), dot(_1123, cross(_1137, _1141)));\n                vec3 param_27 = _1150;\n                int _1154 = fa_cube_face(param_27);\n                int param_28 = _1154;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1181 = vec2(dot(_1150, cross(param_29, param_30)), dot(_1150, param_30)) / vec2(max(dot(_1150, param_29), 9.9999997473787516355514526367188e-05));\n                int _1185 = _1154 / 3;\n                vec2 param_31 = _1115.xy + (vec2(float(_1154 - (_1185 * 3)), float(_1185)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1181.x), 0.5 - (0.5 * _1181.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _831 + 7;\n            vec4 _1215 = fa_light_texel(param_33);\n            if (_1215.z > 0.5)\n            {\n                int param_34 = _831 + 2;\n                int param_35 = _831 + 4;\n                int param_36 = _831 + 5;\n                vec2 param_37 = _1215.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_835 && _1067)\n            {\n                int param_42 = _831 + 6;\n                vec4 _1262 = fa_light_texel(param_42);\n                int param_43 = _831 + 7;\n                vec4 _1267 = fa_light_texel(param_43);\n                bool _1270 = _1262.z > 0.5;\n                bool _1277;\n                if (!_1270)\n                {\n                    _1277 = _1267.z > 0.5;\n                }\n                else\n                {\n                    _1277 = _1270;\n                }\n                if (_1277)\n                {\n                    int param_44 = _831 + 2;\n                    vec4 _1284 = fa_light_texel(param_44);\n                    vec3 _1288 = normalize(_1284.xyz);\n                    int param_45 = _831 + 4;\n                    vec4 _1293 = fa_light_texel(param_45);\n                    int param_46 = _831 + 5;\n                    vec4 _1298 = fa_light_texel(param_46);\n                    if (_1270)\n                    {\n                        vec3 _1306 = -to_light;\n                        float _1313 = _1284.w;\n                        float _1329 = 0.5 / max(dot(_1306, _1288) * (sqrt(max(1.0 - (_1313 * _1313), 0.0)) / max(_1313, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1262.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1306, _1293.xyz) * _1329), 0.5 - (dot(_1306, _1298.xyz) * _1329));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1267.z > 0.5)\n                    {\n                        vec2 param_49 = _1267.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1288;\n                        vec3 param_52 = _1293.xyz;\n                        vec3 param_53 = _1298.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6502 = _844.xyz * atten;\n    if (_835)\n    {\n        _6502 *= fa_light_tint;\n    }\n    int _1398;\n    if (_861)\n    {\n        _1398 = 0;\n    }\n    else\n    {\n        _1398 = ((_847 > 1.5) && (_847 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6502, atten, 1.0, dist, _1398);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5526 = n < 0;\n    bool _5533;\n    if (!_5526)\n    {\n        _5533 = n >= fa_light_count();\n    }\n    else\n    {\n        _5533 = _5526;\n    }\n    if (_5533)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5541 = fa_cl_light(param);\n    int param_1 = _5541;\n    float _5545 = fa_baked_keep(param_1);\n    if (_5545 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5541;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5561 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5561.direction, _5561.color * _5545, _5561.attenuation * _5545, _5561.shadow, _5561._distance, _5561.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3359 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3362 = _3359.w > 0.5;\n    bool _3372;\n    if (_3362)\n    {\n        _3372 = abs(d - _3359.x) <= tol;\n    }\n    else\n    {\n        _3372 = _3362;\n    }\n    if (_3372)\n    {\n        best = min(best, mod(floor(_3359.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2187 = fa_shadow_depth(param, param_1);\n    float _2191;\n    if (conv.x < 0.5)\n    {\n        _2191 = _2187;\n    }\n    else\n    {\n        _2191 = (conv.y * conv.z) / (conv.z - (_2187 * (conv.z - conv.y)));\n    }\n    return _2191;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2237 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2243 = vec2(cos(_2237), sin(_2237));\n    vec2 dir = _2243;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2252;\n        if (k < 0.0)\n        {\n            _2252 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2252 = k;\n        }\n        float _2271 = clamp((_2252 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2290 = sqrt((float(i) + 0.5) * 0.0625) * _2271;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2290));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2304 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2304 < (zr - (_2290 * plane)))\n            {\n                sum += _2304;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2332 = sum / cnt;\n        float _2342;\n        if (k < 0.0)\n        {\n            _2342 = (-k) / max(_2332, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2342 = k;\n        }\n        radius = clamp(((max(zr - _2332, 0.0) * unit) * _2342) / texel_m, 1.5, 16.0);\n        dir = _2243;\n    }\n    float lit = 0.0;\n    int _2368 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2368; i_1++)\n    {\n        float _2387 = sqrt((float(i_1) + 0.5) / float(_2368)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2387));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2387 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2368);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2592 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2599;\n    if (!_2592)\n    {\n        _2599 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2599 = _2592;\n    }\n    if (_2599)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2612 = fa_light_texel(param);\n    float _2613 = _2612.x;\n    if (_2613 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2622 = int(_2613 + 0.5);\n    int param_1 = _2622;\n    vec4 _2626 = fa_light_texel(param_1);\n    int param_2 = _2622 + 1;\n    vec4 _2631 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2634 = _2626.y;\n    if (_2634 > 0.0)\n    {\n        float _2651 = 1.0 - smoothstep(0.75 * _2634, _2634, length(world - fa_shadows[27].xyz));\n        fade = _2651;\n        if (_2651 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2626.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2675 = (_2622 + 2) + (face * 6);\n    int param_4 = _2675;\n    int param_5 = _2675 + 1;\n    int param_6 = _2675 + 3;\n    vec4 _2689 = fa_light_texel(param_6);\n    int param_7 = _2675 + 4;\n    vec4 _2694 = fa_light_texel(param_7);\n    int param_8 = _2675 + 5;\n    vec4 _2699 = fa_light_texel(param_8);\n    float _2711 = _2699.x * max(dot(_2689, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2716 = clamp(dot(n, l), 0.0, 1.0);\n    float _2739 = clamp(dot(n, _2689.xyz), -1.0, 1.0);\n    float _2758 = min(sqrt(1.0 - (_2739 * _2739)) / max(abs(dot(n, world - lpos)) / max(dot(_2689, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2761 = _2631.y;\n    float _2763;\n    if (_2761 > 0.0)\n    {\n        _2763 = _2761;\n    }\n    else\n    {\n        _2763 = 1.5 * _2711;\n    }\n    vec4 _2783 = vec4(world + (n * (_2763 * sqrt(1.0 - (_2716 * _2716)))), 1.0);\n    float _2787 = dot(_2689, _2783);\n    float _2790 = _2699.y;\n    if (_2787 < _2790)\n    {\n        return 1.0;\n    }\n    vec2 _2805 = vec2(dot(fa_light_texel(param_4), _2783), dot(fa_light_texel(param_5), _2783)) / vec2(_2787);\n    float _2807 = _2805.x;\n    bool _2810 = _2807 < _2694.x;\n    bool _2819;\n    if (!_2810)\n    {\n        _2819 = _2807 > _2694.z;\n    }\n    else\n    {\n        _2819 = _2810;\n    }\n    bool _2828;\n    if (!_2819)\n    {\n        _2828 = _2805.y < _2694.y;\n    }\n    else\n    {\n        _2828 = _2819;\n    }\n    bool _2837;\n    if (!_2828)\n    {\n        _2837 = _2805.y > _2694.w;\n    }\n    else\n    {\n        _2837 = _2828;\n    }\n    if (_2837)\n    {\n        return 1.0;\n    }\n    float _2843 = _2631.x;\n    float _2845;\n    if (_2843 > 0.0)\n    {\n        _2845 = _2843;\n    }\n    else\n    {\n        _2845 = 1.5 * _2711;\n    }\n    vec2 param_9 = _2805;\n    vec4 param_10 = _2694;\n    float param_11 = _2787 - (_2845 * (1.0 + (0.5 * _2758)));\n    float param_12 = _2711;\n    float param_13 = 1.0;\n    float param_14 = _2699.z * 0.25;\n    float param_15 = (_2711 * min(_2758, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2790, _2699.z);\n    int param_17 = int(_2626.z + 0.5);\n    float param_18 = _2626.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3390 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3396;\n    if (_3390)\n    {\n        _3396 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3396 = _3390;\n    }\n    bool _3402;\n    if (_3396)\n    {\n        _3402 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3402 = _3396;\n    }\n    if (_3402)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3414 = fa_light_texel(param);\n        float _3415 = _3414.z;\n        if (_3415 > 0.5)\n        {\n            float _3428 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3434 = ((0.00200000009499490261077880859375 * _3428) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3440 = vec4(world, 1.0);\n            float _3445 = dot(fa_mesh_fs_params[28], _3440);\n            if (_3445 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3462 = vec2(dot(fa_mesh_fs_params[26], _3440), dot(fa_mesh_fs_params[27], _3440)) / vec2(_3445);\n                float _3467 = (_3462.x * 0.5) + 0.5;\n                float _3471;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3471 = (_3462.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3471 = 0.5 - (_3462.y * 0.5);\n                }\n                bool _3487 = _3467 >= 0.0;\n                bool _3493;\n                if (_3487)\n                {\n                    _3493 = _3467 < 1.0;\n                }\n                else\n                {\n                    _3493 = _3487;\n                }\n                bool _3499;\n                if (_3493)\n                {\n                    _3499 = _3471 >= 0.0;\n                }\n                else\n                {\n                    _3499 = _3493;\n                }\n                bool _3505;\n                if (_3499)\n                {\n                    _3505 = _3471 < 1.0;\n                }\n                else\n                {\n                    _3505 = _3499;\n                }\n                if (_3505)\n                {\n                    ivec2 _3512 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3523 = clamp(ivec2(vec2(_3467, _3471) * fa_mesh_fs_params[24].zw), ivec2(0), _3512 - ivec2(1));\n                    float _3527;\n                    if (_3415 < 1.5)\n                    {\n                        _3527 = 1.0;\n                    }\n                    else\n                    {\n                        _3527 = (_3415 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3543 = texelFetch(fa_screen_tex_fa_shadow_smp, _3523, 0);\n                    bool _3546 = _3543.w > 0.5;\n                    bool _3556;\n                    if (_3546)\n                    {\n                        _3556 = abs(_3428 - _3543.x) <= _3434;\n                    }\n                    else\n                    {\n                        _3556 = _3546;\n                    }\n                    if (_3556)\n                    {\n                        best = mod(floor(_3543.z / _3527), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3523 + ivec2(-1);\n                        ivec2 param_2 = _3512;\n                        float param_3 = _3428;\n                        float param_4 = _3434;\n                        float param_5 = _3527;\n                        float param_6 = best;\n                        float _3582 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3582;\n                        ivec2 param_7 = _3523 + ivec2(0, -1);\n                        ivec2 param_8 = _3512;\n                        float param_9 = _3428;\n                        float param_10 = _3434;\n                        float param_11 = _3527;\n                        float param_12 = _3582;\n                        float _3597 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3597;\n                        ivec2 param_13 = _3523 + ivec2(1, -1);\n                        ivec2 param_14 = _3512;\n                        float param_15 = _3428;\n                        float param_16 = _3434;\n                        float param_17 = _3527;\n                        float param_18 = _3597;\n                        float _3612 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3612;\n                        ivec2 param_19 = _3523 + ivec2(-1, 0);\n                        ivec2 param_20 = _3512;\n                        float param_21 = _3428;\n                        float param_22 = _3434;\n                        float param_23 = _3527;\n                        float param_24 = _3612;\n                        float _3627 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3627;\n                        ivec2 param_25 = _3523 + ivec2(1, 0);\n                        ivec2 param_26 = _3512;\n                        float param_27 = _3428;\n                        float param_28 = _3434;\n                        float param_29 = _3527;\n                        float param_30 = _3627;\n                        float _3642 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3642;\n                        ivec2 param_31 = _3523 + ivec2(-1, 1);\n                        ivec2 param_32 = _3512;\n                        float param_33 = _3428;\n                        float param_34 = _3434;\n                        float param_35 = _3527;\n                        float param_36 = _3642;\n                        float _3657 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3657;\n                        ivec2 param_37 = _3523 + ivec2(0, 1);\n                        ivec2 param_38 = _3512;\n                        float param_39 = _3428;\n                        float param_40 = _3434;\n                        float param_41 = _3527;\n                        float param_42 = _3657;\n                        float _3672 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3672;\n                        ivec2 param_43 = _3523 + ivec2(1);\n                        ivec2 param_44 = _3512;\n                        float param_45 = _3428;\n                        float param_46 = _3434;\n                        float param_47 = _3527;\n                        float param_48 = _3672;\n                        float _3687 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3687;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3695;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3695 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3695 = best;\n                        }\n                        return _3695;\n                    }\n                }\n            }\n            float _3718;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3718 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3718 = 1.0;\n            }\n            return _3718;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2130;\n    if (i == 0)\n    {\n        _2130 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2146;\n        if (i == 1)\n        {\n            _2146 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2154;\n            if (i == 2)\n            {\n                _2154 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2154 = fa_shadows[24].w;\n            }\n            _2146 = _2154;\n        }\n        _2130 = _2146;\n    }\n    return _2130;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2433 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2438 = clamp(dot(n, l), 0.0, 1.0);\n    float _2444 = sqrt(1.0 - (_2438 * _2438));\n    float _2452 = min(_2444 / max(_2438, 0.20000000298023223876953125), 4.0);\n    float _2457;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2457 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2457 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2482 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2457 * _2444)), 1.0);\n    float _2489 = _2482.x;\n    bool _2492 = _2489 < fa_shadows[ci * 1 + 16].x;\n    bool _2501;\n    if (!_2492)\n    {\n        _2501 = _2489 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2501 = _2492;\n    }\n    bool _2510;\n    if (!_2501)\n    {\n        _2510 = _2482.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2510 = _2501;\n    }\n    bool _2519;\n    if (!_2510)\n    {\n        _2519 = _2482.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2519 = _2510;\n    }\n    bool _2526;\n    if (!_2519)\n    {\n        _2526 = _2482.z > 1.0;\n    }\n    else\n    {\n        _2526 = _2519;\n    }\n    if (_2526)\n    {\n        return -1.0;\n    }\n    float _2534;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2534 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2534 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2482.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2482.z - ((_2534 * (1.0 + (0.5 * _2452))) / _2433);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2433;\n    float param_5 = _2433 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2452, 3.0)) * 0.5) / _2433;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2912 = int(fa_shadows[25].x + 0.5);\n    if (_2912 < 1)\n    {\n        return 1.0;\n    }\n    float _2927 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2912 - 1;\n    if (_2927 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2939 = _2912 > 1;\n    bool _2946;\n    if (_2939)\n    {\n        _2946 = _2927 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2946 = _2939;\n    }\n    if (_2946)\n    {\n        ci = 1;\n    }\n    bool _2950 = _2912 > 2;\n    bool _2957;\n    if (_2950)\n    {\n        _2957 = _2927 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2957 = _2950;\n    }\n    if (_2957)\n    {\n        ci = 2;\n    }\n    bool _2961 = _2912 > 3;\n    bool _2968;\n    if (_2961)\n    {\n        _2968 = _2927 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2968 = _2961;\n    }\n    if (_2968)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2979 = min(_2912, 4);\n    float _3020;\n    for (int c = ci; c < _2979; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2999 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2999;\n            break;\n        }\n        if (_2999 < 0.0)\n        {\n            continue;\n        }\n        s = _2999;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3020 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3020 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3039 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3020, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2927 - (fa_shadow_split_at(param_7) - _3039)) / _3039, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3071;\n        if ((ci + 1) < _2912)\n        {\n            _3071 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3071 = 1.0;\n        }\n        s = mix(s, _3071, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3176 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3182;\n    if (_3176)\n    {\n        _3182 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3182 = _3176;\n    }\n    if (_3182)\n    {\n        float _3196 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3204 = vec4(fa_world_pos, 1.0);\n        float _3210 = dot(fa_mesh_fs_params[28], _3204);\n        if (_3210 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3229 = vec2(dot(fa_mesh_fs_params[26], _3204), dot(fa_mesh_fs_params[27], _3204)) / vec2(_3210);\n            float _3234 = (_3229.x * 0.5) + 0.5;\n            float _3238;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3238 = (_3229.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3238 = 0.5 - (_3229.y * 0.5);\n            }\n            bool _3254 = _3234 >= 0.0;\n            bool _3260;\n            if (_3254)\n            {\n                _3260 = _3234 < 1.0;\n            }\n            else\n            {\n                _3260 = _3254;\n            }\n            bool _3266;\n            if (_3260)\n            {\n                _3266 = _3238 >= 0.0;\n            }\n            else\n            {\n                _3266 = _3260;\n            }\n            bool _3272;\n            if (_3266)\n            {\n                _3272 = _3238 < 1.0;\n            }\n            else\n            {\n                _3272 = _3266;\n            }\n            if (_3272)\n            {\n                vec4 _3297 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3234, _3238) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3300 = _3297.w > 0.5;\n                bool _3316;\n                if (_3300)\n                {\n                    _3316 = abs(_3196 - _3297.x) <= (((0.00200000009499490261077880859375 * _3196) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3316 = _3300;\n                }\n                if (_3316)\n                {\n                    float _3322;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3322 = min(_3297.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3322 = _3297.y;\n                    }\n                    return _3322;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5012 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5019;\n    if (!_5012)\n    {\n        _5019 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5019 = _5012;\n    }\n    if (_5019)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5032 = fa_light_texel(param);\n    float _5033 = _5032.y;\n    float len = _5033;\n    if (_5033 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5045 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5054 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5045);\n    if (_5054 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5060 = len;\n    float _5063 = min(_5060, 0.89999997615814208984375 * dist);\n    len = _5063;\n    float _5068 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5045);\n    float _5073 = _5068 + (0.5 * _5063);\n    vec3 _5079 = world + (gn * _5068);\n    float _5081 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5142;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5096 = (float(k) + _5081) * 0.083333335816860198974609375;\n        vec3 _5104 = _5079 + (l * (_5096 * len));\n        vec4 _5110 = vec4(_5104, 1.0);\n        float _5115 = dot(fa_mesh_fs_params[28], _5110);\n        if (_5115 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5133 = vec2(dot(fa_mesh_fs_params[26], _5110), dot(fa_mesh_fs_params[27], _5110)) / vec2(_5115);\n        float _5137 = _5133.x * 0.5;\n        float _5138 = _5137 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5142 = (_5133.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5142 = 0.5 - (_5133.y * 0.5);\n        }\n        bool _5158 = _5138 < 0.0;\n        bool _5165;\n        if (!_5158)\n        {\n            _5165 = _5138 >= 1.0;\n        }\n        else\n        {\n            _5165 = _5158;\n        }\n        bool _5172;\n        if (!_5165)\n        {\n            _5172 = _5142 < 0.0;\n        }\n        else\n        {\n            _5172 = _5165;\n        }\n        bool _5179;\n        if (!_5172)\n        {\n            _5179 = _5142 >= 1.0;\n        }\n        else\n        {\n            _5179 = _5172;\n        }\n        if (_5179)\n        {\n            break;\n        }\n        vec4 _5203 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5138, _5142) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5203.w < 0.5)\n        {\n            continue;\n        }\n        float _5221 = (dot(fa_mesh_fs_params[29].xyz, _5104) + fa_mesh_fs_params[29].w) - _5203.x;\n        if ((_5221 > _5068) && (_5221 < _5073))\n        {\n            occ = max(occ, (1.0 - (_5096 * _5096)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5138, 0.5 - _5137), min(_5142, 1.0 - _5142))));\n        }\n    }\n    return 1.0 - (occ * _5054);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5353 = fa_baked_keep(param);\n    if (_5353 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5379 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6648 = _5379.color;\n    float _6649 = _5379.attenuation;\n    float _6650 = _5379.shadow;\n    bool _5382 = _5379.type == 0;\n    if (_5382 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5379.direction;\n        float _5393 = fa_shadow_factor(param_5, param_6);\n        _6650 = _5393;\n        _6648 *= _5393;\n    }\n    else\n    {\n        bool _5404 = _5379.type != 0;\n        bool _5410;\n        if (_5404)\n        {\n            _5410 = _6649 > 0.0;\n        }\n        else\n        {\n            _5410 = _5404;\n        }\n        if (_5410)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5379.direction;\n            float _5429 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6650 = _5429;\n            _6648 *= _5429;\n        }\n    }\n    bool _5439 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5445;\n    if (_5439)\n    {\n        _5445 = _6649 > 0.0;\n    }\n    else\n    {\n        _5445 = _5439;\n    }\n    if (_5445)\n    {\n        float _5452;\n        if (_5382)\n        {\n            _5452 = 1000000000.0;\n        }\n        else\n        {\n            _5452 = _5379._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5379.direction;\n        float param_18 = _5452;\n        float _5470 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6650 *= _5470;\n        _6648 *= _5470;\n    }\n    float _5483 = _6649;\n    float _5484 = _5483 * _5353;\n    _6649 = _5484;\n    vec3 _5488 = _6648;\n    vec3 _5489 = _5488 * _5353;\n    _6648 = _5489;\n    return LightSample(_5379.direction, _5489, _5484, _6650, _5379._distance, _5379.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5500 = n < 0;\n    bool _5507;\n    if (!_5500)\n    {\n        _5507 = n >= fa_light_count();\n    }\n    else\n    {\n        _5507 = _5500;\n    }\n    if (_5507)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5522 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5522;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4397 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4405 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4408 = int(_4397);\n    int _4411 = int(_4405);\n    float _4421 = _4405 - float(_4411);\n    int _4477 = (_4408 * 9) + _4411;\n    int _4497 = ((_4408 + 1) * 9) + _4411;\n    return mix(mix(_4472[_4477], _4472[_4477 + 1], _4421), mix(_4472[_4497], _4472[_4497 + 1], _4421), _4397 - float(_4408));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6514 = false;\n    float _6515 = 1.0;\n    float _6516 = 1.0;\n    float _6517 = 1.0;\n    float _6518 = 0.0;\n    float _6519 = 0.0;\n    float _6520 = 0.0;\n    float _6521 = 0.0;\n    float _6523 = 1.0;\n    bool _6524 = false;\n    vec3 _6525 = vec3(0.0);\n    float _6526 = 1.0;\n    float _6527 = 1.0;\n    float _6528 = 1.0;\n    float _6529 = 0.0;\n    float _6530 = 0.0;\n    vec3 _6531 = vec3(1.0, 0.0, 0.0);\n    vec3 _6532 = vec3(0.0, 0.0, 1.0);\n    float _6533 = 1.0;\n    float _6534 = 1.0;\n    float _4548 = clamp(s.specular, 0.0, 1.0);\n    float _4552 = clamp(s.ior, 1.0, 3.0);\n    bool _4557 = (_4548 != 1.0) || (_4552 != 1.5);\n    bool _4566;\n    if (!_4557)\n    {\n        _4566 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4566 = _4557;\n    }\n    if (_4566)\n    {\n        float _4574 = (_4552 - 1.0) / (_4552 + 1.0);\n        f0 = mix(min(vec3(_4574 * _4574) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4548, s.albedo, vec3(metallic));\n        _6515 = mix(_4548, 1.0, metallic);\n        _6514 = true;\n    }\n    float _4601 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4601 > 0.0)\n    {\n        float _4609 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6518 = _4601;\n        _6519 = _4609;\n        float _4616 = _4609 * _4609;\n        _6520 = _4616;\n        _6521 = _4616 * _4616;\n        float _4628 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6523 = _4628;\n        _6516 = 1.0 - (_4601 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4628, 0.0, 1.0), 5.0))));\n        _6514 = true;\n    }\n    vec3 _4647 = max(s.sheen_color, vec3(0.0));\n    float _4656 = max(_4647.x, max(_4647.y, _4647.z));\n    if (_4656 > 0.0)\n    {\n        float _4664 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6524 = true;\n        _6525 = _4647;\n        _6526 = _4664;\n        _6527 = _4664 * _4664;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4664;\n        float _4681 = fa_sheen_albedo(param, param_1);\n        _6529 = _4681;\n        _6528 = 1.0 - min(_4656 * _4681, 1.0);\n        _6514 = true;\n    }\n    _6517 = _6516 * _6528;\n    float _4700 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4700 != 0.0)\n    {\n        vec3 _4715 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4715;\n        if (dot(_4715, _4715) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4727 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4727.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4727.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4727.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4731 = t;\n        vec3 _4732 = normalize(_4731);\n        t = _4732;\n        vec3 _4757 = normalize((_4732 * cos(s.anisotropy_rotation)) + ((cross(n, _4732) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6531 = _4757;\n        _6532 = cross(n, _4757);\n        float _4767 = roughness * roughness;\n        float _4773 = mix(_4767, 1.0, _4700 * _4700);\n        bool _4775 = _4700 > 0.0;\n        _6533 = _4775 ? _4773 : _4767;\n        _6534 = _4775 ? _4767 : _4773;\n        _6530 = _4700;\n        _6514 = true;\n    }\n    return FaLayers(_6514, _6515, _6516, _6517, _6518, _6519, _6520, _6521, i.world_normal, _6523, _6524, _6525, _6526, _6527, _6528, _6529, _6530, _6531, _6532, _6533, _6534);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4329 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4332 = _4329.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4332 * _4332, exp2((-9.27999973297119140625) * ndv)) * _4332) + _4329.y)) + _4329.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3765 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3768 = _3765.x;\n    float _3770 = _3765.z;\n    vec2 e = vec2(_3768, _3770);\n    if (_3765.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3770)) * ((_3768 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3768)) * ((_3770 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3817;\n    if (lv == 0)\n    {\n        _3817 = 0.0;\n    }\n    else\n    {\n        _3817 = res + 2.0;\n    }\n    float _3827;\n    if (lv == 0)\n    {\n        _3827 = 0.0;\n    }\n    else\n    {\n        _3827 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3817, _3827)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3873;\n    if (res > 64.5)\n    {\n        _3873 = 5.0;\n    }\n    else\n    {\n        _3873 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3888 = clamp(rough, 0.0, 1.0) * (_3873 - 1.0);\n    int _3895 = int(min(floor(_3888), _3873 - 2.0));\n    float _3900 = _3888 - float(_3895);\n    vec3 param = d;\n    vec2 _3904 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3895;\n    vec2 param_4 = _3904;\n    vec3 _3914 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3900 < 0.00200000009499490261077880859375)\n    {\n        return _3914;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3895 + 1;\n    vec2 param_8 = _3904;\n    return mix(_3914, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3900));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3951 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3958 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3965 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3971 = dot(bx.xyz, d);\n    float _3975 = dot(by.xyz, d);\n    float _3979 = dot(bz.xyz, d);\n    float _3985;\n    if (_3971 > 9.9999999747524270787835121154785e-07)\n    {\n        _3985 = (1.0 - _3951) / _3971;\n    }\n    else\n    {\n        float _3999;\n        if (_3971 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3999 = ((-1.0) - _3951) / _3971;\n        }\n        else\n        {\n            _3999 = 1000000015047466219876688855040.0;\n        }\n        _3985 = _3999;\n    }\n    float tx = _3985;\n    float _4016;\n    if (_3975 > 9.9999999747524270787835121154785e-07)\n    {\n        _4016 = (1.0 - _3958) / _3975;\n    }\n    else\n    {\n        float _4029;\n        if (_3975 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4029 = ((-1.0) - _3958) / _3975;\n        }\n        else\n        {\n            _4029 = 1000000015047466219876688855040.0;\n        }\n        _4016 = _4029;\n    }\n    float ty = _4016;\n    float _4045;\n    if (_3979 > 9.9999999747524270787835121154785e-07)\n    {\n        _4045 = (1.0 - _3965) / _3979;\n    }\n    else\n    {\n        float _4058;\n        if (_3979 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4058 = ((-1.0) - _3965) / _3979;\n        }\n        else\n        {\n            _4058 = 1000000015047466219876688855040.0;\n        }\n        _4045 = _4058;\n    }\n    float _4070 = tx;\n    float _4073 = (_4070 > 0.0) ? _4070 : 1000000015047466219876688855040.0;\n    tx = _4073;\n    float _4074 = ty;\n    float _4077 = (_4074 > 0.0) ? _4074 : 1000000015047466219876688855040.0;\n    ty = _4077;\n    float _4087 = min(_4073, min(_4077, (_4045 > 0.0) ? _4045 : 1000000015047466219876688855040.0));\n    if (_4087 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4103 = (fa_world_pos + (d * _4087)) - posw.xyz;\n    vec3 _4108;\n    if (dot(_4103, _4103) > 1.0000000133514319600180897396058e-10)\n    {\n        _4108 = normalize(_4103);\n    }\n    else\n    {\n        _4108 = d;\n    }\n    return _4108;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4154 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4154 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4184 = rough * rough;\n            float _4215 = 0.60000002384185791015625 * _4184;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4184)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4215, 0.0500000007450580596923828125 + _4215, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4184 * 0.60000002384185791015625));\n        }\n        outc = base * _4154;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4274 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4274 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4306 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4306 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4808;\n        if (L.aniso >= 0.0)\n        {\n            _4808 = L.b;\n        }\n        else\n        {\n            _4808 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4808, v), _4808), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4844 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4844.x) + (vec3(L.f90) * _4844.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4902 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4902.x) + _4902.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4371 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4371.x) + vec3(_4371.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4941 = clamp(s.metallic, 0.0, 1.0);\n    float _4945 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4952 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4941));\n    vec3 f0 = _4952;\n    vec3 _4956 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4956;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4941;\n    float param_5 = _4945;\n    vec3 param_6 = _4952;\n    FaLayers _4973 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4973.on)\n    {\n        FaLayers param_7 = _4973;\n        vec3 param_8 = _4956;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4945;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4956;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4945;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5591 = fa_light_unshadowed(param, param_1);\n        float _5599 = dot(_5591.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5599 > bestPower)\n        {\n            bestPower = _5599;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5628 = fa_light(param_2, param_3);\n        float _5636;\n        if (dot(s.normal, _5628.direction) > 0.5)\n        {\n            _5636 = 1.0;\n        }\n        else\n        {\n            _5636 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5628.color) * _5636);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3099 = int(fa_shadows[25].x + 0.5);\n    float _3109 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3114 = _3099 > 0;\n    bool _3123;\n    if (_3114)\n    {\n        int param = _3099 - 1;\n        _3123 = _3109 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3123 = _3114;\n    }\n    if (_3123)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3129 = _3099 > 1;\n        bool _3136;\n        if (_3129)\n        {\n            _3136 = _3109 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3136 = _3129;\n        }\n        if (_3136)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3142 = _3099 > 2;\n        bool _3149;\n        if (_3142)\n        {\n            _3149 = _3109 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3149 = _3142;\n        }\n        if (_3149)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3155 = _3099 > 3;\n        bool _3162;\n        if (_3155)\n        {\n            _3162 = _3109 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3162 = _3155;\n        }\n        if (_3162)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6368 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6368 = -_6368;\n    }\n    vec3 _6038 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n    Surface _6046 = fa_standard_surface(param_1);\n    vec3 _6399 = _6046.albedo;\n    float _6400 = _6046.alpha;\n    vec3 _6401 = _6046.normal;\n    float _6402 = _6046.metallic;\n    float _6403 = _6046.roughness;\n    float _6404 = _6046.occlusion;\n    vec3 _6405 = _6046.emission;\n    float _6406 = _6046.clearcoat;\n    float _6407 = _6046.clearcoat_roughness;\n    vec3 _6408 = _6046.sheen_color;\n    float _6409 = _6046.sheen_roughness;\n    float _6410 = _6046.anisotropy;\n    float _6411 = _6046.anisotropy_rotation;\n    float _6412 = _6046.specular;\n    float _6413 = _6046.ior;\n    vec3 _6414 = _6046.specular_color;\n    float _6415 = _6046.transmission;\n    float _6416 = _6046.thickness;\n    vec3 _6417 = _6046.attenuation_color;\n    float _6418 = _6046.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n    Surface param_3 = _6046;\n    surface(param_2, param_3);\n    _6399 = param_3.albedo;\n    _6400 = param_3.alpha;\n    _6401 = param_3.normal;\n    _6402 = param_3.metallic;\n    _6403 = param_3.roughness;\n    _6404 = param_3.occlusion;\n    _6405 = param_3.emission;\n    _6406 = param_3.clearcoat;\n    _6407 = param_3.clearcoat_roughness;\n    _6408 = param_3.sheen_color;\n    _6409 = param_3.sheen_roughness;\n    _6410 = param_3.anisotropy;\n    _6411 = param_3.anisotropy_rotation;\n    _6412 = param_3.specular;\n    _6413 = param_3.ior;\n    _6414 = param_3.specular_color;\n    _6415 = param_3.transmission;\n    _6416 = param_3.thickness;\n    _6417 = param_3.attenuation_color;\n    _6418 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6368;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6399 = param_6;\n    _6401 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6399;\n    }\n    else\n    {\n        vec3 _6085 = _6401;\n        vec3 _6086 = normalize(_6085);\n        _6401 = _6086;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n        Surface param_9 = Surface(_6399, _6400, _6086, _6402, _6403, _6404, _6405, _6406, _6407, _6408, _6409, _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418);\n        vec3 _6097 = lighting(param_8, param_9);\n        result = _6097;\n    }\n    vec3 _6101 = result;\n    vec3 _6102 = _6101 + _6405;\n    result = _6102;\n    vec3 param_10 = _6102;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _6111 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6118;\n    if (!_6111)\n    {\n        _6118 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6118 = _6111;\n    }\n    if (_6118)\n    {\n        vec3 _6127 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6133 = dot(_6127, fa_mesh_fs_params[9].xyz);\n        bool _6137 = fa_mesh_fs_params[9].w > 0.5;\n        float _6138;\n        if (_6137)\n        {\n            _6138 = _6133;\n        }\n        else\n        {\n            _6138 = length(_6127);\n        }\n        float _6150 = _6138 - fa_mesh_fs_params[8].x;\n        if (_6150 > 0.0)\n        {\n            float _6159 = fa_mesh_fs_params[7].w * _6150;\n            float tau = _6159 * _6159;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6175;\n                if (_6137)\n                {\n                    _6175 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6133);\n                }\n                else\n                {\n                    _6175 = fa_mesh_fs_params[0].y;\n                }\n                float _6196 = mix(_6175, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6138, 0.0, 1.0));\n                float _6200 = fa_world_pos.y - _6196;\n                float _6205 = _6196 - fa_mesh_fs_params[8].z;\n                float _6210 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6213 = _6205 <= 0.0;\n                bool _6214 = !_6213;\n                bool _6220;\n                if (_6214)\n                {\n                    _6220 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6220 = _6213;\n                }\n                float _6221;\n                if (_6220)\n                {\n                    _6221 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6221 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6205, 80.0));\n                }\n                bool _6248;\n                if (_6214)\n                {\n                    _6248 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6248 = _6213;\n                }\n                float _6249;\n                if (_6248)\n                {\n                    _6249 = fa_mesh_fs_params[8].y * _6205;\n                }\n                else\n                {\n                    _6249 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6205, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6274 = _6210 <= 0.0;\n                bool _6281;\n                if (!_6274)\n                {\n                    _6281 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6281 = _6274;\n                }\n                float _6282;\n                if (_6281)\n                {\n                    _6282 = fa_mesh_fs_params[8].y * _6210;\n                }\n                else\n                {\n                    _6282 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6210, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6309;\n                if (abs(_6200) < 0.001000000047497451305389404296875)\n                {\n                    _6309 = _6221;\n                }\n                else\n                {\n                    _6309 = (_6282 - _6249) / _6200;\n                }\n                tau += (_6150 * max(_6309, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6400);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_487",
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
            "inst_name": "_2140",
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
            "inst_name": "_5642",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4472[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1416 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1423;\n    if (!_1416)\n    {\n        _1423 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1423 = _1416;\n    }\n    bool _1431;\n    if (!_1423)\n    {\n        _1431 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1431 = _1423;\n    }\n    bool _1438;\n    if (!_1431)\n    {\n        _1438 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1438 = _1431;\n    }\n    bool _1445;\n    if (!_1438)\n    {\n        _1445 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1445 = _1438;\n    }\n    if (_1445)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1455 = vec4(world_pos, 1.0);\n    float _1461 = dot(fa_mesh_fs_params[16], _1455);\n    if (!(_1461 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1483 = vec2(dot(fa_mesh_fs_params[14], _1455), dot(fa_mesh_fs_params[15], _1455)) / vec2(_1461);\n    int _1487 = int(fa_mesh_fs_params[18].x);\n    int _1491 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1491) + clamp(int(floor(((_1483.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1491 - 1)) * _1487)) + clamp(int(floor(((_1483.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1487 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1567 = fa_cluster_texel(param);\n    return ivec2(int(_1567.x), int(_1567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _5298 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _5301 = fwidth(_5298);\n    bool _5304 = fa_mesh_fs_params[25].y > 0.5;\n    bool _5311;\n    if (!_5304)\n    {\n        _5311 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _5311 = _5304;\n    }\n    if (_5311)\n    {\n        fa_rt_slope = min(1.5 * _5301, 0.100000001490116119384765625 * _5298);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5327 = fa_cluster_lookup(param);\n    fa_cl_slot = _5327.x;\n    fa_cl_local = _5327.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5703 = fa_linear_to_srgb(param);\n        c = _5703;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5711 = fa_srgb_to_linear(param_1);\n            c = _5711;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _368;\n    if (i.front_facing)\n    {\n        _368 = i.world_normal;\n    }\n    else\n    {\n        _368 = -i.world_normal;\n    }\n    vec3 _392 = normalize(i.world_tangent.xyz - (_368 * dot(_368, i.world_tangent.xyz)));\n    vec3 _420 = normalize(((_392 * m.x) + ((cross(_368, _392) * i.world_tangent.w) * m.y)) + (_368 * m.z));\n    vec3 _423;\n    if (i.front_facing)\n    {\n        _423 = _420;\n    }\n    else\n    {\n        _423 = -_420;\n    }\n    return _423;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5743 = fa_tex_fix(param_2, param_3);\n    vec4 _6914 = base_t;\n    _6914.x = _5743.x;\n    _6914.y = _5743.y;\n    _6914.z = _5743.z;\n    base_t = _6914;\n    vec4 _5757 = (_6914 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6696 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5791 = fa_tex_fix(param_6, param_7);\n        vec3 _5794 = (_5791 * 2.0) - vec3(1.0);\n        vec2 _5799 = _5794.xy * fa_mesh_fs_params[6].x;\n        vec3 _6922 = _5794;\n        _6922.x = _5799.x;\n        _6922.y = _5799.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6922;\n        _6696 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5829 = fa_tex_fix(param_12, param_13);\n    vec4 _6925 = mrt;\n    _6925.x = _5829.x;\n    _6925.y = _5829.y;\n    _6925.z = _5829.z;\n    mrt = _6925;\n    vec4 _5859 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5859.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5870 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5902 = fa_tex_fix(param_20, param_21);\n    float _6701 = fa_mesh_fs_params[20].x;\n    float _6702 = fa_mesh_fs_params[20].y;\n    float _6705 = fa_mesh_fs_params[20].z;\n    float _6704 = fa_mesh_fs_params[21].w;\n    float _6707 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6701 *= _5870.y;\n            _6702 *= _5870.z;\n            _6704 *= _5859.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6705 *= mrt.x;\n            _6707 *= mrt.w;\n        }\n    }\n    return Surface(_5757.xyz, _5757.w, _6696, clamp(fa_mesh_fs_params[5].x * _5829.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5870.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5902), _6701, _6702, fa_mesh_fs_params[21].xyz, _6704, _6705, fa_mesh_fs_params[20].w, _6707, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1647 = rect.zw - rect.xy;\n    vec2 _1651 = _1647 * atlas;\n    vec2 _1655 = ddx * _1651;\n    vec2 _1659 = ddy * _1651;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1647), clamp(0.5 * log2(max(max(dot(_1655, _1655), dot(_1659, _1659)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1692 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1699;\n    if (!_1692)\n    {\n        _1699 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1699 = _1692;\n    }\n    if (_1699)\n    {\n        return;\n    }\n    vec3 _1705 = dFdx(world_pos);\n    vec3 _1708 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1712 = fa_cluster_texel(param);\n    int _1716 = int(_1712.w);\n    if (_1716 < 1)\n    {\n        return;\n    }\n    int _1726 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1726;\n    vec4 _1730 = fa_light_texel(param_1);\n    vec2 _1733 = _1730.yz;\n    int _1737 = int(_1730.w);\n    int param_2 = _1726 + 1;\n    vec4 _1742 = fa_light_texel(param_2);\n    float _1743 = _1742.x;\n    int _1749 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1753 = int(_1712.z);\n    vec3 _2018;\n    for (int k = 0; k < _1716; k++)\n    {\n        int _1766 = _1753 + k;\n        int param_3 = _1737 + (_1766 >> 2);\n        int _1783 = (_1726 + 2) + (int(fa_light_texel(param_3)[_1766 & 3]) * 7);\n        int param_4 = _1783 + 6;\n        vec4 _1788 = fa_light_texel(param_4);\n        if (((int(_1788.w + 0.5) >> _1749) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1783;\n        vec4 _1803 = fa_light_texel(param_5);\n        int param_6 = _1783 + 1;\n        vec4 _1808 = fa_light_texel(param_6);\n        int param_7 = _1783 + 2;\n        vec4 _1813 = fa_light_texel(param_7);\n        vec3 _1816 = _1803.xyz;\n        float _1821 = dot(_1816, world_pos) + _1803.w;\n        vec3 _1823 = _1808.xyz;\n        float _1828 = dot(_1823, world_pos) + _1808.w;\n        vec3 _1830 = _1813.xyz;\n        float _1835 = dot(_1830, world_pos) + _1813.w;\n        bool _1840 = abs(_1821) > 0.5;\n        bool _1848;\n        if (!_1840)\n        {\n            _1848 = abs(_1828) > 0.5;\n        }\n        else\n        {\n            _1848 = _1840;\n        }\n        bool _1856;\n        if (!_1848)\n        {\n            _1856 = abs(_1835) > 0.5;\n        }\n        else\n        {\n            _1856 = _1848;\n        }\n        if (_1856)\n        {\n            continue;\n        }\n        float _1871 = clamp(dot(geo_normal, normalize(_1830)) * _1788.z, 0.0, 1.0);\n        if (_1871 <= 0.0)\n        {\n            continue;\n        }\n        float _1891 = (clamp((0.5 - abs(_1835)) * 10.0, 0.0, 1.0) * _1871) * _1788.x;\n        vec2 _1899 = vec2(_1821 + 0.5, 0.5 - _1828);\n        vec2 _1909 = vec2(dot(_1816, _1705), dot(_1823, _1705));\n        vec2 _1919 = vec2(dot(_1816, _1708), dot(_1823, _1708));\n        int param_8 = _1783 + 5;\n        vec4 _1924 = fa_light_texel(param_8);\n        int param_9 = _1783 + 3;\n        vec4 _1929 = fa_light_texel(param_9);\n        int param_10 = _1783 + 4;\n        vec4 _1934 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1924.xyz;\n        bool _1944 = _1929.z > _1929.x;\n        if (_1944)\n        {\n            vec4 param_11 = _1929;\n            vec2 param_12 = _1899;\n            vec2 param_13 = _1733;\n            vec2 param_14 = _1909;\n            vec2 param_15 = _1919;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1743 > 0.5) && (_1743 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1970 = fa_dc_to_linear(param_16);\n                vec4 _6784 = tx;\n                _6784.x = _1970.x;\n                _6784.y = _1970.y;\n                _6784.z = _1970.z;\n                tx = _6784;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1891 * tex_a) * _1924.w, 0.0, 1.0)));\n        if (_1934.z > _1934.x)\n        {\n            vec4 param_17 = _1934;\n            vec2 param_18 = _1899;\n            vec2 param_19 = _1733;\n            vec2 param_20 = _1909;\n            vec2 param_21 = _1919;\n            vec4 _2014 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1743 > 1.5)\n            {\n                vec3 param_22 = _2014.xyz;\n                vec3 _2024 = fa_dc_to_srgb(param_22);\n                _2018 = _2024;\n            }\n            else\n            {\n                _2018 = _2014.xyz;\n            }\n            vec3 _2033 = (_2018 * 2.0) - vec3(1.0);\n            vec2 _2038 = _2033.xy * _1788.y;\n            vec3 _2060 = (normalize(_1816) * _2038.x) + (normalize(_1823) * _2038.y);\n            vec3 _2063 = normalize(normal);\n            normal = normalize(mix(_2063, normalize((_2063 * max(_2033.z, 0.0500000007450580596923828125)) + (_2060 - (_2063 * dot(_2063, _2060)))), vec3(clamp(_1891 * (_1944 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5268;\n    if (fa_lm.z > 0.5)\n    {\n        _5268 = 0.0;\n    }\n    else\n    {\n        _5268 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5279 = _5268 < 1.0;\n    bool _5285;\n    if (_5279)\n    {\n        int param = li;\n        _5285 = fa_light_baked(param);\n    }\n    else\n    {\n        _5285 = _5279;\n    }\n    return _5285 ? _5268 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _665 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _678 = (c - (ru * hx)) - p;\n        vec3 _684 = ru * (2.0 * hx);\n        float _690 = max(dot(_684, _684), 9.9999999392252902907785028219223e-09);\n        float _694 = dot(_678, _684);\n        float t = clamp((-_694) / _690, 0.0, 1.0);\n        if (_665)\n        {\n            float _709 = dot(r, _684);\n            float _715 = _690 - (_709 * _709);\n            if (abs(_715) > (9.9999997473787516355514526367188e-06 * _690))\n            {\n                t = clamp(((dot(r, _678) * _709) - _694) / _715, 0.0, 1.0);\n            }\n        }\n        return (p + _678) + (_684 * t);\n    }\n    vec3 q = p;\n    float _747 = dot(r, axis);\n    bool _755;\n    if (_665)\n    {\n        _755 = abs(_747) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _755 = _665;\n    }\n    if (_755)\n    {\n        float _765 = dot(c - p, axis) / _747;\n        if (_765 > 0.0)\n        {\n            q = p + (r * _765);\n        }\n    }\n    vec3 _778 = q - c;\n    vec2 xy = vec2(dot(_778, ru), dot(_778, uu));\n    if (shape > 0.5)\n    {\n        float _793 = length(xy);\n        if (_793 > hx)\n        {\n            xy *= (hx / _793);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _585 = dot(d, right);\n    float _589 = dot(d, up);\n    float _600;\n    if (((_585 * _585) + (_589 * _589)) > 1.0000000133514319600180897396058e-10)\n    {\n        _600 = atan(_589, _585) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _600 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_600 - floor(_600)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _435 = abs(d);\n    float _437 = _435.x;\n    float _439 = _435.y;\n    bool _440 = _437 >= _439;\n    bool _448;\n    if (_440)\n    {\n        _448 = _437 >= _435.z;\n    }\n    else\n    {\n        _448 = _440;\n    }\n    int _449;\n    if (_448)\n    {\n        _449 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _463;\n        if (_439 >= _435.z)\n        {\n            _463 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _463 = (d.z > 0.0) ? 4 : 5;\n        }\n        _449 = _463;\n    }\n    return _449;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _831 = fa_light_base(param);\n    bool _835 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _831;\n    vec4 _839 = fa_light_texel(param_1);\n    int param_2 = _831 + 1;\n    vec4 _844 = fa_light_texel(param_2);\n    float _847 = _844.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _859 = _835 && (_847 > 2.5);\n    fa_light_is_area = _859;\n    bool _861 = _847 < 0.5;\n    vec3 l;\n    if (_861)\n    {\n        l = normalize(_839.xyz);\n        if (_835)\n        {\n            int param_3 = _831 + 6;\n            vec4 _875 = fa_light_texel(param_3);\n            if (_875.z > 0.5)\n            {\n                int param_4 = _831 + 4;\n                vec4 _885 = fa_light_texel(param_4);\n                int param_5 = _831 + 5;\n                vec4 _890 = fa_light_texel(param_5);\n                vec2 param_6 = _875.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _885.xyz) * _885.w, (-dot(world_pos, _890.xyz)) * _890.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _920 = _839.xyz;\n        vec3 _922 = _920 - world_pos;\n        vec3 to_light = _922;\n        float _925 = length(_922);\n        float reach = _925;\n        bool front = true;\n        if (_859)\n        {\n            int param_8 = _831 + 7;\n            reach = max(_925 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _831 + 4;\n            vec4 _949 = fa_light_texel(param_9);\n            int param_10 = _831 + 5;\n            vec4 _954 = fa_light_texel(param_10);\n            int param_11 = _831 + 6;\n            vec4 _959 = fa_light_texel(param_11);\n            float _960 = _959.w;\n            int param_12 = _831 + 2;\n            vec3 _967 = normalize(fa_light_texel(param_12).xyz);\n            bool _969 = _960 > 1.5;\n            bool _977;\n            if (!_969)\n            {\n                _977 = dot(_967, to_light) < 0.0;\n            }\n            else\n            {\n                _977 = _969;\n            }\n            front = _977;\n            vec3 r = vec3(0.0);\n            vec3 _986 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _990 = dot(n, n) > 0.5;\n            bool _998;\n            if (_990)\n            {\n                _998 = dot(_986, _986) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            if (_998)\n            {\n                r = reflect(-normalize(_986), normalize(n));\n            }\n            vec3 param_13 = _920;\n            vec3 param_14 = _967;\n            vec3 param_15 = _949.xyz;\n            vec3 param_16 = _954.xyz;\n            float param_17 = _949.w;\n            float param_18 = _954.w;\n            float param_19 = _960;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1034 = length(to_light);\n        dist = _1034;\n        l = to_light / vec3(max(_1034, 9.9999997473787516355514526367188e-05));\n        float _1048 = reach / max(_839.w, 0.001000000047497451305389404296875);\n        float _1054 = clamp(1.0 - (_1048 * _1048), 0.0, 1.0);\n        float _1056;\n        if (front)\n        {\n            _1056 = _1054 * _1054;\n        }\n        else\n        {\n            _1056 = 0.0;\n        }\n        atten = _1056;\n        bool _1067 = _847 < 2.5;\n        if ((_847 > 1.5) && _1067)\n        {\n            int param_22 = _831 + 2;\n            vec4 _1075 = fa_light_texel(param_22);\n            float _1085 = _1075.w;\n            int param_23 = _831 + 3;\n            vec4 _1090 = fa_light_texel(param_23);\n            float _1091 = _1090.x;\n            float cos_inner = _1091;\n            if (_1091 > 1.5)\n            {\n                cos_inner = mix(_1085, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1085, cos_inner, dot(-l, normalize(_1075.xyz)));\n        }\n        if (_835 && (_847 < 1.5))\n        {\n            int param_24 = _831 + 6;\n            vec4 _1115 = fa_light_texel(param_24);\n            if (_1115.z > 0.5)\n            {\n                vec3 _1123 = -to_light;\n                int param_25 = _831 + 4;\n                int param_26 = _831 + 5;\n                vec3 _1137 = fa_light_texel(param_25).xyz;\n                vec3 _1141 = fa_light_texel(param_26).xyz;\n                vec3 _1150 = vec3(dot(_1123, _1137), dot(_1123, _1141), dot(_1123, cross(_1137, _1141)));\n                vec3 param_27 = _1150;\n                int _1154 = fa_cube_face(param_27);\n                int param_28 = _1154;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1181 = vec2(dot(_1150, cross(param_29, param_30)), dot(_1150, param_30)) / vec2(max(dot(_1150, param_29), 9.9999997473787516355514526367188e-05));\n                int _1185 = _1154 / 3;\n                vec2 param_31 = _1115.xy + (vec2(float(_1154 - (_1185 * 3)), float(_1185)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1181.x), 0.5 - (0.5 * _1181.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _831 + 7;\n            vec4 _1215 = fa_light_texel(param_33);\n            if (_1215.z > 0.5)\n            {\n                int param_34 = _831 + 2;\n                int param_35 = _831 + 4;\n                int param_36 = _831 + 5;\n                vec2 param_37 = _1215.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_835 && _1067)\n            {\n                int param_42 = _831 + 6;\n                vec4 _1262 = fa_light_texel(param_42);\n                int param_43 = _831 + 7;\n                vec4 _1267 = fa_light_texel(param_43);\n                bool _1270 = _1262.z > 0.5;\n                bool _1277;\n                if (!_1270)\n                {\n                    _1277 = _1267.z > 0.5;\n                }\n                else\n                {\n                    _1277 = _1270;\n                }\n                if (_1277)\n                {\n                    int param_44 = _831 + 2;\n                    vec4 _1284 = fa_light_texel(param_44);\n                    vec3 _1288 = normalize(_1284.xyz);\n                    int param_45 = _831 + 4;\n                    vec4 _1293 = fa_light_texel(param_45);\n                    int param_46 = _831 + 5;\n                    vec4 _1298 = fa_light_texel(param_46);\n                    if (_1270)\n                    {\n                        vec3 _1306 = -to_light;\n                        float _1313 = _1284.w;\n                        float _1329 = 0.5 / max(dot(_1306, _1288) * (sqrt(max(1.0 - (_1313 * _1313), 0.0)) / max(_1313, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1262.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1306, _1293.xyz) * _1329), 0.5 - (dot(_1306, _1298.xyz) * _1329));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1267.z > 0.5)\n                    {\n                        vec2 param_49 = _1267.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1288;\n                        vec3 param_52 = _1293.xyz;\n                        vec3 param_53 = _1298.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6502 = _844.xyz * atten;\n    if (_835)\n    {\n        _6502 *= fa_light_tint;\n    }\n    int _1398;\n    if (_861)\n    {\n        _1398 = 0;\n    }\n    else\n    {\n        _1398 = ((_847 > 1.5) && (_847 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6502, atten, 1.0, dist, _1398);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5526 = n < 0;\n    bool _5533;\n    if (!_5526)\n    {\n        _5533 = n >= fa_light_count();\n    }\n    else\n    {\n        _5533 = _5526;\n    }\n    if (_5533)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5541 = fa_cl_light(param);\n    int param_1 = _5541;\n    float _5545 = fa_baked_keep(param_1);\n    if (_5545 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5541;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5561 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5561.direction, _5561.color * _5545, _5561.attenuation * _5545, _5561.shadow, _5561._distance, _5561.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3359 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3362 = _3359.w > 0.5;\n    bool _3372;\n    if (_3362)\n    {\n        _3372 = abs(d - _3359.x) <= tol;\n    }\n    else\n    {\n        _3372 = _3362;\n    }\n    if (_3372)\n    {\n        best = min(best, mod(floor(_3359.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2187 = fa_shadow_depth(param, param_1);\n    float _2191;\n    if (conv.x < 0.5)\n    {\n        _2191 = _2187;\n    }\n    else\n    {\n        _2191 = (conv.y * conv.z) / (conv.z - (_2187 * (conv.z - conv.y)));\n    }\n    return _2191;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2237 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2243 = vec2(cos(_2237), sin(_2237));\n    vec2 dir = _2243;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2252;\n        if (k < 0.0)\n        {\n            _2252 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2252 = k;\n        }\n        float _2271 = clamp((_2252 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2290 = sqrt((float(i) + 0.5) * 0.0625) * _2271;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2290));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2304 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2304 < (zr - (_2290 * plane)))\n            {\n                sum += _2304;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2332 = sum / cnt;\n        float _2342;\n        if (k < 0.0)\n        {\n            _2342 = (-k) / max(_2332, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2342 = k;\n        }\n        radius = clamp(((max(zr - _2332, 0.0) * unit) * _2342) / texel_m, 1.5, 16.0);\n        dir = _2243;\n    }\n    float lit = 0.0;\n    int _2368 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2368; i_1++)\n    {\n        float _2387 = sqrt((float(i_1) + 0.5) / float(_2368)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2387));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2387 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2368);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2592 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2599;\n    if (!_2592)\n    {\n        _2599 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2599 = _2592;\n    }\n    if (_2599)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2612 = fa_light_texel(param);\n    float _2613 = _2612.x;\n    if (_2613 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2622 = int(_2613 + 0.5);\n    int param_1 = _2622;\n    vec4 _2626 = fa_light_texel(param_1);\n    int param_2 = _2622 + 1;\n    vec4 _2631 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2634 = _2626.y;\n    if (_2634 > 0.0)\n    {\n        float _2651 = 1.0 - smoothstep(0.75 * _2634, _2634, length(world - fa_shadows[27].xyz));\n        fade = _2651;\n        if (_2651 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2626.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2675 = (_2622 + 2) + (face * 6);\n    int param_4 = _2675;\n    int param_5 = _2675 + 1;\n    int param_6 = _2675 + 3;\n    vec4 _2689 = fa_light_texel(param_6);\n    int param_7 = _2675 + 4;\n    vec4 _2694 = fa_light_texel(param_7);\n    int param_8 = _2675 + 5;\n    vec4 _2699 = fa_light_texel(param_8);\n    float _2711 = _2699.x * max(dot(_2689, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2716 = clamp(dot(n, l), 0.0, 1.0);\n    float _2739 = clamp(dot(n, _2689.xyz), -1.0, 1.0);\n    float _2758 = min(sqrt(1.0 - (_2739 * _2739)) / max(abs(dot(n, world - lpos)) / max(dot(_2689, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2761 = _2631.y;\n    float _2763;\n    if (_2761 > 0.0)\n    {\n        _2763 = _2761;\n    }\n    else\n    {\n        _2763 = 1.5 * _2711;\n    }\n    vec4 _2783 = vec4(world + (n * (_2763 * sqrt(1.0 - (_2716 * _2716)))), 1.0);\n    float _2787 = dot(_2689, _2783);\n    float _2790 = _2699.y;\n    if (_2787 < _2790)\n    {\n        return 1.0;\n    }\n    vec2 _2805 = vec2(dot(fa_light_texel(param_4), _2783), dot(fa_light_texel(param_5), _2783)) / vec2(_2787);\n    float _2807 = _2805.x;\n    bool _2810 = _2807 < _2694.x;\n    bool _2819;\n    if (!_2810)\n    {\n        _2819 = _2807 > _2694.z;\n    }\n    else\n    {\n        _2819 = _2810;\n    }\n    bool _2828;\n    if (!_2819)\n    {\n        _2828 = _2805.y < _2694.y;\n    }\n    else\n    {\n        _2828 = _2819;\n    }\n    bool _2837;\n    if (!_2828)\n    {\n        _2837 = _2805.y > _2694.w;\n    }\n    else\n    {\n        _2837 = _2828;\n    }\n    if (_2837)\n    {\n        return 1.0;\n    }\n    float _2843 = _2631.x;\n    float _2845;\n    if (_2843 > 0.0)\n    {\n        _2845 = _2843;\n    }\n    else\n    {\n        _2845 = 1.5 * _2711;\n    }\n    vec2 param_9 = _2805;\n    vec4 param_10 = _2694;\n    float param_11 = _2787 - (_2845 * (1.0 + (0.5 * _2758)));\n    float param_12 = _2711;\n    float param_13 = 1.0;\n    float param_14 = _2699.z * 0.25;\n    float param_15 = (_2711 * min(_2758, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2790, _2699.z);\n    int param_17 = int(_2626.z + 0.5);\n    float param_18 = _2626.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3390 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3396;\n    if (_3390)\n    {\n        _3396 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3396 = _3390;\n    }\n    bool _3402;\n    if (_3396)\n    {\n        _3402 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3402 = _3396;\n    }\n    if (_3402)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3414 = fa_light_texel(param);\n        float _3415 = _3414.z;\n        if (_3415 > 0.5)\n        {\n            float _3428 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3434 = ((0.00200000009499490261077880859375 * _3428) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3440 = vec4(world, 1.0);\n            float _3445 = dot(fa_mesh_fs_params[28], _3440);\n            if (_3445 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3462 = vec2(dot(fa_mesh_fs_params[26], _3440), dot(fa_mesh_fs_params[27], _3440)) / vec2(_3445);\n                float _3467 = (_3462.x * 0.5) + 0.5;\n                float _3471;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3471 = (_3462.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3471 = 0.5 - (_3462.y * 0.5);\n                }\n                bool _3487 = _3467 >= 0.0;\n                bool _3493;\n                if (_3487)\n                {\n                    _3493 = _3467 < 1.0;\n                }\n                else\n                {\n                    _3493 = _3487;\n                }\n                bool _3499;\n                if (_3493)\n                {\n                    _3499 = _3471 >= 0.0;\n                }\n                else\n                {\n                    _3499 = _3493;\n                }\n                bool _3505;\n                if (_3499)\n                {\n                    _3505 = _3471 < 1.0;\n                }\n                else\n                {\n                    _3505 = _3499;\n                }\n                if (_3505)\n                {\n                    ivec2 _3512 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3523 = clamp(ivec2(vec2(_3467, _3471) * fa_mesh_fs_params[24].zw), ivec2(0), _3512 - ivec2(1));\n                    float _3527;\n                    if (_3415 < 1.5)\n                    {\n                        _3527 = 1.0;\n                    }\n                    else\n                    {\n                        _3527 = (_3415 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3543 = texelFetch(fa_screen_tex_fa_shadow_smp, _3523, 0);\n                    bool _3546 = _3543.w > 0.5;\n                    bool _3556;\n                    if (_3546)\n                    {\n                        _3556 = abs(_3428 - _3543.x) <= _3434;\n                    }\n                    else\n                    {\n                        _3556 = _3546;\n                    }\n                    if (_3556)\n                    {\n                        best = mod(floor(_3543.z / _3527), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3523 + ivec2(-1);\n                        ivec2 param_2 = _3512;\n                        float param_3 = _3428;\n                        float param_4 = _3434;\n                        float param_5 = _3527;\n                        float param_6 = best;\n                        float _3582 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3582;\n                        ivec2 param_7 = _3523 + ivec2(0, -1);\n                        ivec2 param_8 = _3512;\n                        float param_9 = _3428;\n                        float param_10 = _3434;\n                        float param_11 = _3527;\n                        float param_12 = _3582;\n                        float _3597 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3597;\n                        ivec2 param_13 = _3523 + ivec2(1, -1);\n                        ivec2 param_14 = _3512;\n                        float param_15 = _3428;\n                        float param_16 = _3434;\n                        float param_17 = _3527;\n                        float param_18 = _3597;\n                        float _3612 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3612;\n                        ivec2 param_19 = _3523 + ivec2(-1, 0);\n                        ivec2 param_20 = _3512;\n                        float param_21 = _3428;\n                        float param_22 = _3434;\n                        float param_23 = _3527;\n                        float param_24 = _3612;\n                        float _3627 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3627;\n                        ivec2 param_25 = _3523 + ivec2(1, 0);\n                        ivec2 param_26 = _3512;\n                        float param_27 = _3428;\n                        float param_28 = _3434;\n                        float param_29 = _3527;\n                        float param_30 = _3627;\n                        float _3642 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3642;\n                        ivec2 param_31 = _3523 + ivec2(-1, 1);\n                        ivec2 param_32 = _3512;\n                        float param_33 = _3428;\n                        float param_34 = _3434;\n                        float param_35 = _3527;\n                        float param_36 = _3642;\n                        float _3657 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3657;\n                        ivec2 param_37 = _3523 + ivec2(0, 1);\n                        ivec2 param_38 = _3512;\n                        float param_39 = _3428;\n                        float param_40 = _3434;\n                        float param_41 = _3527;\n                        float param_42 = _3657;\n                        float _3672 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3672;\n                        ivec2 param_43 = _3523 + ivec2(1);\n                        ivec2 param_44 = _3512;\n                        float param_45 = _3428;\n                        float param_46 = _3434;\n                        float param_47 = _3527;\n                        float param_48 = _3672;\n                        float _3687 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3687;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3695;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3695 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3695 = best;\n                        }\n                        return _3695;\n                    }\n                }\n            }\n            float _3718;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3718 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3718 = 1.0;\n            }\n            return _3718;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2130;\n    if (i == 0)\n    {\n        _2130 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2146;\n        if (i == 1)\n        {\n            _2146 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2154;\n            if (i == 2)\n            {\n                _2154 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2154 = fa_shadows[24].w;\n            }\n            _2146 = _2154;\n        }\n        _2130 = _2146;\n    }\n    return _2130;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2433 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2438 = clamp(dot(n, l), 0.0, 1.0);\n    float _2444 = sqrt(1.0 - (_2438 * _2438));\n    float _2452 = min(_2444 / max(_2438, 0.20000000298023223876953125), 4.0);\n    float _2457;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2457 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2457 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2482 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2457 * _2444)), 1.0);\n    float _2489 = _2482.x;\n    bool _2492 = _2489 < fa_shadows[ci * 1 + 16].x;\n    bool _2501;\n    if (!_2492)\n    {\n        _2501 = _2489 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2501 = _2492;\n    }\n    bool _2510;\n    if (!_2501)\n    {\n        _2510 = _2482.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2510 = _2501;\n    }\n    bool _2519;\n    if (!_2510)\n    {\n        _2519 = _2482.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2519 = _2510;\n    }\n    bool _2526;\n    if (!_2519)\n    {\n        _2526 = _2482.z > 1.0;\n    }\n    else\n    {\n        _2526 = _2519;\n    }\n    if (_2526)\n    {\n        return -1.0;\n    }\n    float _2534;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2534 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2534 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2482.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2482.z - ((_2534 * (1.0 + (0.5 * _2452))) / _2433);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2433;\n    float param_5 = _2433 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2452, 3.0)) * 0.5) / _2433;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2912 = int(fa_shadows[25].x + 0.5);\n    if (_2912 < 1)\n    {\n        return 1.0;\n    }\n    float _2927 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2912 - 1;\n    if (_2927 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2939 = _2912 > 1;\n    bool _2946;\n    if (_2939)\n    {\n        _2946 = _2927 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2946 = _2939;\n    }\n    if (_2946)\n    {\n        ci = 1;\n    }\n    bool _2950 = _2912 > 2;\n    bool _2957;\n    if (_2950)\n    {\n        _2957 = _2927 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2957 = _2950;\n    }\n    if (_2957)\n    {\n        ci = 2;\n    }\n    bool _2961 = _2912 > 3;\n    bool _2968;\n    if (_2961)\n    {\n        _2968 = _2927 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2968 = _2961;\n    }\n    if (_2968)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2979 = min(_2912, 4);\n    float _3020;\n    for (int c = ci; c < _2979; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2999 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2999;\n            break;\n        }\n        if (_2999 < 0.0)\n        {\n            continue;\n        }\n        s = _2999;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3020 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3020 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3039 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3020, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2927 - (fa_shadow_split_at(param_7) - _3039)) / _3039, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3071;\n        if ((ci + 1) < _2912)\n        {\n            _3071 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3071 = 1.0;\n        }\n        s = mix(s, _3071, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3176 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3182;\n    if (_3176)\n    {\n        _3182 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3182 = _3176;\n    }\n    if (_3182)\n    {\n        float _3196 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3204 = vec4(fa_world_pos, 1.0);\n        float _3210 = dot(fa_mesh_fs_params[28], _3204);\n        if (_3210 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3229 = vec2(dot(fa_mesh_fs_params[26], _3204), dot(fa_mesh_fs_params[27], _3204)) / vec2(_3210);\n            float _3234 = (_3229.x * 0.5) + 0.5;\n            float _3238;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3238 = (_3229.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3238 = 0.5 - (_3229.y * 0.5);\n            }\n            bool _3254 = _3234 >= 0.0;\n            bool _3260;\n            if (_3254)\n            {\n                _3260 = _3234 < 1.0;\n            }\n            else\n            {\n                _3260 = _3254;\n            }\n            bool _3266;\n            if (_3260)\n            {\n                _3266 = _3238 >= 0.0;\n            }\n            else\n            {\n                _3266 = _3260;\n            }\n            bool _3272;\n            if (_3266)\n            {\n                _3272 = _3238 < 1.0;\n            }\n            else\n            {\n                _3272 = _3266;\n            }\n            if (_3272)\n            {\n                vec4 _3297 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3234, _3238) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3300 = _3297.w > 0.5;\n                bool _3316;\n                if (_3300)\n                {\n                    _3316 = abs(_3196 - _3297.x) <= (((0.00200000009499490261077880859375 * _3196) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3316 = _3300;\n                }\n                if (_3316)\n                {\n                    float _3322;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3322 = min(_3297.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3322 = _3297.y;\n                    }\n                    return _3322;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5012 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5019;\n    if (!_5012)\n    {\n        _5019 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5019 = _5012;\n    }\n    if (_5019)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5032 = fa_light_texel(param);\n    float _5033 = _5032.y;\n    float len = _5033;\n    if (_5033 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5045 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5054 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5045);\n    if (_5054 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5060 = len;\n    float _5063 = min(_5060, 0.89999997615814208984375 * dist);\n    len = _5063;\n    float _5068 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5045);\n    float _5073 = _5068 + (0.5 * _5063);\n    vec3 _5079 = world + (gn * _5068);\n    float _5081 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5142;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5096 = (float(k) + _5081) * 0.083333335816860198974609375;\n        vec3 _5104 = _5079 + (l * (_5096 * len));\n        vec4 _5110 = vec4(_5104, 1.0);\n        float _5115 = dot(fa_mesh_fs_params[28], _5110);\n        if (_5115 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5133 = vec2(dot(fa_mesh_fs_params[26], _5110), dot(fa_mesh_fs_params[27], _5110)) / vec2(_5115);\n        float _5137 = _5133.x * 0.5;\n        float _5138 = _5137 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5142 = (_5133.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5142 = 0.5 - (_5133.y * 0.5);\n        }\n        bool _5158 = _5138 < 0.0;\n        bool _5165;\n        if (!_5158)\n        {\n            _5165 = _5138 >= 1.0;\n        }\n        else\n        {\n            _5165 = _5158;\n        }\n        bool _5172;\n        if (!_5165)\n        {\n            _5172 = _5142 < 0.0;\n        }\n        else\n        {\n            _5172 = _5165;\n        }\n        bool _5179;\n        if (!_5172)\n        {\n            _5179 = _5142 >= 1.0;\n        }\n        else\n        {\n            _5179 = _5172;\n        }\n        if (_5179)\n        {\n            break;\n        }\n        vec4 _5203 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5138, _5142) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5203.w < 0.5)\n        {\n            continue;\n        }\n        float _5221 = (dot(fa_mesh_fs_params[29].xyz, _5104) + fa_mesh_fs_params[29].w) - _5203.x;\n        if ((_5221 > _5068) && (_5221 < _5073))\n        {\n            occ = max(occ, (1.0 - (_5096 * _5096)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5138, 0.5 - _5137), min(_5142, 1.0 - _5142))));\n        }\n    }\n    return 1.0 - (occ * _5054);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5353 = fa_baked_keep(param);\n    if (_5353 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5379 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6648 = _5379.color;\n    float _6649 = _5379.attenuation;\n    float _6650 = _5379.shadow;\n    bool _5382 = _5379.type == 0;\n    if (_5382 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5379.direction;\n        float _5393 = fa_shadow_factor(param_5, param_6);\n        _6650 = _5393;\n        _6648 *= _5393;\n    }\n    else\n    {\n        bool _5404 = _5379.type != 0;\n        bool _5410;\n        if (_5404)\n        {\n            _5410 = _6649 > 0.0;\n        }\n        else\n        {\n            _5410 = _5404;\n        }\n        if (_5410)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5379.direction;\n            float _5429 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6650 = _5429;\n            _6648 *= _5429;\n        }\n    }\n    bool _5439 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5445;\n    if (_5439)\n    {\n        _5445 = _6649 > 0.0;\n    }\n    else\n    {\n        _5445 = _5439;\n    }\n    if (_5445)\n    {\n        float _5452;\n        if (_5382)\n        {\n            _5452 = 1000000000.0;\n        }\n        else\n        {\n            _5452 = _5379._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5379.direction;\n        float param_18 = _5452;\n        float _5470 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6650 *= _5470;\n        _6648 *= _5470;\n    }\n    float _5483 = _6649;\n    float _5484 = _5483 * _5353;\n    _6649 = _5484;\n    vec3 _5488 = _6648;\n    vec3 _5489 = _5488 * _5353;\n    _6648 = _5489;\n    return LightSample(_5379.direction, _5489, _5484, _6650, _5379._distance, _5379.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5500 = n < 0;\n    bool _5507;\n    if (!_5500)\n    {\n        _5507 = n >= fa_light_count();\n    }\n    else\n    {\n        _5507 = _5500;\n    }\n    if (_5507)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5522 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5522;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4397 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4405 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4408 = int(_4397);\n    int _4411 = int(_4405);\n    float _4421 = _4405 - float(_4411);\n    int _4477 = (_4408 * 9) + _4411;\n    int _4497 = ((_4408 + 1) * 9) + _4411;\n    return mix(mix(_4472[_4477], _4472[_4477 + 1], _4421), mix(_4472[_4497], _4472[_4497 + 1], _4421), _4397 - float(_4408));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6514 = false;\n    float _6515 = 1.0;\n    float _6516 = 1.0;\n    float _6517 = 1.0;\n    float _6518 = 0.0;\n    float _6519 = 0.0;\n    float _6520 = 0.0;\n    float _6521 = 0.0;\n    float _6523 = 1.0;\n    bool _6524 = false;\n    vec3 _6525 = vec3(0.0);\n    float _6526 = 1.0;\n    float _6527 = 1.0;\n    float _6528 = 1.0;\n    float _6529 = 0.0;\n    float _6530 = 0.0;\n    vec3 _6531 = vec3(1.0, 0.0, 0.0);\n    vec3 _6532 = vec3(0.0, 0.0, 1.0);\n    float _6533 = 1.0;\n    float _6534 = 1.0;\n    float _4548 = clamp(s.specular, 0.0, 1.0);\n    float _4552 = clamp(s.ior, 1.0, 3.0);\n    bool _4557 = (_4548 != 1.0) || (_4552 != 1.5);\n    bool _4566;\n    if (!_4557)\n    {\n        _4566 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4566 = _4557;\n    }\n    if (_4566)\n    {\n        float _4574 = (_4552 - 1.0) / (_4552 + 1.0);\n        f0 = mix(min(vec3(_4574 * _4574) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4548, s.albedo, vec3(metallic));\n        _6515 = mix(_4548, 1.0, metallic);\n        _6514 = true;\n    }\n    float _4601 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4601 > 0.0)\n    {\n        float _4609 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6518 = _4601;\n        _6519 = _4609;\n        float _4616 = _4609 * _4609;\n        _6520 = _4616;\n        _6521 = _4616 * _4616;\n        float _4628 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6523 = _4628;\n        _6516 = 1.0 - (_4601 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4628, 0.0, 1.0), 5.0))));\n        _6514 = true;\n    }\n    vec3 _4647 = max(s.sheen_color, vec3(0.0));\n    float _4656 = max(_4647.x, max(_4647.y, _4647.z));\n    if (_4656 > 0.0)\n    {\n        float _4664 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6524 = true;\n        _6525 = _4647;\n        _6526 = _4664;\n        _6527 = _4664 * _4664;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4664;\n        float _4681 = fa_sheen_albedo(param, param_1);\n        _6529 = _4681;\n        _6528 = 1.0 - min(_4656 * _4681, 1.0);\n        _6514 = true;\n    }\n    _6517 = _6516 * _6528;\n    float _4700 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4700 != 0.0)\n    {\n        vec3 _4715 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4715;\n        if (dot(_4715, _4715) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4727 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4727.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4727.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4727.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4731 = t;\n        vec3 _4732 = normalize(_4731);\n        t = _4732;\n        vec3 _4757 = normalize((_4732 * cos(s.anisotropy_rotation)) + ((cross(n, _4732) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6531 = _4757;\n        _6532 = cross(n, _4757);\n        float _4767 = roughness * roughness;\n        float _4773 = mix(_4767, 1.0, _4700 * _4700);\n        bool _4775 = _4700 > 0.0;\n        _6533 = _4775 ? _4773 : _4767;\n        _6534 = _4775 ? _4767 : _4773;\n        _6530 = _4700;\n        _6514 = true;\n    }\n    return FaLayers(_6514, _6515, _6516, _6517, _6518, _6519, _6520, _6521, i.world_normal, _6523, _6524, _6525, _6526, _6527, _6528, _6529, _6530, _6531, _6532, _6533, _6534);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4329 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4332 = _4329.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4332 * _4332, exp2((-9.27999973297119140625) * ndv)) * _4332) + _4329.y)) + _4329.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3765 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3768 = _3765.x;\n    float _3770 = _3765.z;\n    vec2 e = vec2(_3768, _3770);\n    if (_3765.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3770)) * ((_3768 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3768)) * ((_3770 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3817;\n    if (lv == 0)\n    {\n        _3817 = 0.0;\n    }\n    else\n    {\n        _3817 = res + 2.0;\n    }\n    float _3827;\n    if (lv == 0)\n    {\n        _3827 = 0.0;\n    }\n    else\n    {\n        _3827 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3817, _3827)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3873;\n    if (res > 64.5)\n    {\n        _3873 = 5.0;\n    }\n    else\n    {\n        _3873 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3888 = clamp(rough, 0.0, 1.0) * (_3873 - 1.0);\n    int _3895 = int(min(floor(_3888), _3873 - 2.0));\n    float _3900 = _3888 - float(_3895);\n    vec3 param = d;\n    vec2 _3904 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3895;\n    vec2 param_4 = _3904;\n    vec3 _3914 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3900 < 0.00200000009499490261077880859375)\n    {\n        return _3914;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3895 + 1;\n    vec2 param_8 = _3904;\n    return mix(_3914, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3900));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3951 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3958 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3965 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3971 = dot(bx.xyz, d);\n    float _3975 = dot(by.xyz, d);\n    float _3979 = dot(bz.xyz, d);\n    float _3985;\n    if (_3971 > 9.9999999747524270787835121154785e-07)\n    {\n        _3985 = (1.0 - _3951) / _3971;\n    }\n    else\n    {\n        float _3999;\n        if (_3971 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3999 = ((-1.0) - _3951) / _3971;\n        }\n        else\n        {\n            _3999 = 1000000015047466219876688855040.0;\n        }\n        _3985 = _3999;\n    }\n    float tx = _3985;\n    float _4016;\n    if (_3975 > 9.9999999747524270787835121154785e-07)\n    {\n        _4016 = (1.0 - _3958) / _3975;\n    }\n    else\n    {\n        float _4029;\n        if (_3975 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4029 = ((-1.0) - _3958) / _3975;\n        }\n        else\n        {\n            _4029 = 1000000015047466219876688855040.0;\n        }\n        _4016 = _4029;\n    }\n    float ty = _4016;\n    float _4045;\n    if (_3979 > 9.9999999747524270787835121154785e-07)\n    {\n        _4045 = (1.0 - _3965) / _3979;\n    }\n    else\n    {\n        float _4058;\n        if (_3979 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4058 = ((-1.0) - _3965) / _3979;\n        }\n        else\n        {\n            _4058 = 1000000015047466219876688855040.0;\n        }\n        _4045 = _4058;\n    }\n    float _4070 = tx;\n    float _4073 = (_4070 > 0.0) ? _4070 : 1000000015047466219876688855040.0;\n    tx = _4073;\n    float _4074 = ty;\n    float _4077 = (_4074 > 0.0) ? _4074 : 1000000015047466219876688855040.0;\n    ty = _4077;\n    float _4087 = min(_4073, min(_4077, (_4045 > 0.0) ? _4045 : 1000000015047466219876688855040.0));\n    if (_4087 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4103 = (fa_world_pos + (d * _4087)) - posw.xyz;\n    vec3 _4108;\n    if (dot(_4103, _4103) > 1.0000000133514319600180897396058e-10)\n    {\n        _4108 = normalize(_4103);\n    }\n    else\n    {\n        _4108 = d;\n    }\n    return _4108;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4154 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4154 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4184 = rough * rough;\n            float _4215 = 0.60000002384185791015625 * _4184;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4184)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4215, 0.0500000007450580596923828125 + _4215, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4184 * 0.60000002384185791015625));\n        }\n        outc = base * _4154;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4274 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4274 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4306 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4306 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4808;\n        if (L.aniso >= 0.0)\n        {\n            _4808 = L.b;\n        }\n        else\n        {\n            _4808 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4808, v), _4808), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4844 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4844.x) + (vec3(L.f90) * _4844.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4902 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4902.x) + _4902.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4371 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4371.x) + vec3(_4371.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4941 = clamp(s.metallic, 0.0, 1.0);\n    float _4945 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4952 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4941));\n    vec3 f0 = _4952;\n    vec3 _4956 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4956;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4941;\n    float param_5 = _4945;\n    vec3 param_6 = _4952;\n    FaLayers _4973 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4973.on)\n    {\n        FaLayers param_7 = _4973;\n        vec3 param_8 = _4956;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4945;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4956;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4945;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5591 = fa_light_unshadowed(param, param_1);\n        float _5599 = dot(_5591.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5599 > bestPower)\n        {\n            bestPower = _5599;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5628 = fa_light(param_2, param_3);\n        float _5636;\n        if (dot(s.normal, _5628.direction) > 0.5)\n        {\n            _5636 = 1.0;\n        }\n        else\n        {\n            _5636 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5628.color) * _5636);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3099 = int(fa_shadows[25].x + 0.5);\n    float _3109 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3114 = _3099 > 0;\n    bool _3123;\n    if (_3114)\n    {\n        int param = _3099 - 1;\n        _3123 = _3109 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3123 = _3114;\n    }\n    if (_3123)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3129 = _3099 > 1;\n        bool _3136;\n        if (_3129)\n        {\n            _3136 = _3109 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3136 = _3129;\n        }\n        if (_3136)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3142 = _3099 > 2;\n        bool _3149;\n        if (_3142)\n        {\n            _3149 = _3109 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3149 = _3142;\n        }\n        if (_3149)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3155 = _3099 > 3;\n        bool _3162;\n        if (_3155)\n        {\n            _3162 = _3109 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3162 = _3155;\n        }\n        if (_3162)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _6368 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6368 = -_6368;\n    }\n    vec3 _6038 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n    Surface _6046 = fa_standard_surface(param_1);\n    vec3 _6399 = _6046.albedo;\n    float _6400 = _6046.alpha;\n    vec3 _6401 = _6046.normal;\n    float _6402 = _6046.metallic;\n    float _6403 = _6046.roughness;\n    float _6404 = _6046.occlusion;\n    vec3 _6405 = _6046.emission;\n    float _6406 = _6046.clearcoat;\n    float _6407 = _6046.clearcoat_roughness;\n    vec3 _6408 = _6046.sheen_color;\n    float _6409 = _6046.sheen_roughness;\n    float _6410 = _6046.anisotropy;\n    float _6411 = _6046.anisotropy_rotation;\n    float _6412 = _6046.specular;\n    float _6413 = _6046.ior;\n    vec3 _6414 = _6046.specular_color;\n    float _6415 = _6046.transmission;\n    float _6416 = _6046.thickness;\n    vec3 _6417 = _6046.attenuation_color;\n    float _6418 = _6046.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n    Surface param_3 = _6046;\n    surface(param_2, param_3);\n    _6399 = param_3.albedo;\n    _6400 = param_3.alpha;\n    _6401 = param_3.normal;\n    _6402 = param_3.metallic;\n    _6403 = param_3.roughness;\n    _6404 = param_3.occlusion;\n    _6405 = param_3.emission;\n    _6406 = param_3.clearcoat;\n    _6407 = param_3.clearcoat_roughness;\n    _6408 = param_3.sheen_color;\n    _6409 = param_3.sheen_roughness;\n    _6410 = param_3.anisotropy;\n    _6411 = param_3.anisotropy_rotation;\n    _6412 = param_3.specular;\n    _6413 = param_3.ior;\n    _6414 = param_3.specular_color;\n    _6415 = param_3.transmission;\n    _6416 = param_3.thickness;\n    _6417 = param_3.attenuation_color;\n    _6418 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6368;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6399 = param_6;\n    _6401 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6399;\n    }\n    else\n    {\n        vec3 _6085 = _6401;\n        vec3 _6086 = normalize(_6085);\n        _6401 = _6086;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6368, fa_world_tangent, fa_uv, fa_vertex_color, _6038, gl_FrontFacing);\n        Surface param_9 = Surface(_6399, _6400, _6086, _6402, _6403, _6404, _6405, _6406, _6407, _6408, _6409, _6410, _6411, _6412, _6413, _6414, _6415, _6416, _6417, _6418);\n        vec3 _6097 = lighting(param_8, param_9);\n        result = _6097;\n    }\n    vec3 _6101 = result;\n    vec3 _6102 = _6101 + _6405;\n    result = _6102;\n    vec3 param_10 = _6102;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _6111 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6118;\n    if (!_6111)\n    {\n        _6118 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6118 = _6111;\n    }\n    if (_6118)\n    {\n        vec3 _6127 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6133 = dot(_6127, fa_mesh_fs_params[9].xyz);\n        bool _6137 = fa_mesh_fs_params[9].w > 0.5;\n        float _6138;\n        if (_6137)\n        {\n            _6138 = _6133;\n        }\n        else\n        {\n            _6138 = length(_6127);\n        }\n        float _6150 = _6138 - fa_mesh_fs_params[8].x;\n        if (_6150 > 0.0)\n        {\n            float _6159 = fa_mesh_fs_params[7].w * _6150;\n            float tau = _6159 * _6159;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6175;\n                if (_6137)\n                {\n                    _6175 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6133);\n                }\n                else\n                {\n                    _6175 = fa_mesh_fs_params[0].y;\n                }\n                float _6196 = mix(_6175, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6138, 0.0, 1.0));\n                float _6200 = fa_world_pos.y - _6196;\n                float _6205 = _6196 - fa_mesh_fs_params[8].z;\n                float _6210 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6213 = _6205 <= 0.0;\n                bool _6214 = !_6213;\n                bool _6220;\n                if (_6214)\n                {\n                    _6220 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6220 = _6213;\n                }\n                float _6221;\n                if (_6220)\n                {\n                    _6221 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6221 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6205, 80.0));\n                }\n                bool _6248;\n                if (_6214)\n                {\n                    _6248 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6248 = _6213;\n                }\n                float _6249;\n                if (_6248)\n                {\n                    _6249 = fa_mesh_fs_params[8].y * _6205;\n                }\n                else\n                {\n                    _6249 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6205, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6274 = _6210 <= 0.0;\n                bool _6281;\n                if (!_6274)\n                {\n                    _6281 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6281 = _6274;\n                }\n                float _6282;\n                if (_6281)\n                {\n                    _6282 = fa_mesh_fs_params[8].y * _6210;\n                }\n                else\n                {\n                    _6282 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6210, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6309;\n                if (abs(_6200) < 0.001000000047497451305389404296875)\n                {\n                    _6309 = _6221;\n                }\n                else\n                {\n                    _6309 = (_6282 - _6249) / _6200;\n                }\n                tau += (_6150 * max(_6309, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6400);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_487",
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
            "inst_name": "_2140",
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
            "inst_name": "_5642",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "inst_name": "_225",
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
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "inst_name": "_470",
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
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    }
  }
}
