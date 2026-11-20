{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3528[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1369 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1376;\n    if (!_1369)\n    {\n        _1376 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1376 = _1369;\n    }\n    bool _1384;\n    if (!_1376)\n    {\n        _1384 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1384 = _1376;\n    }\n    bool _1391;\n    if (!_1384)\n    {\n        _1391 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1391 = _1384;\n    }\n    bool _1398;\n    if (!_1391)\n    {\n        _1398 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1398 = _1391;\n    }\n    if (_1398)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1408 = vec4(world_pos, 1.0);\n    float _1414 = dot(fa_mesh_fs_params[16], _1408);\n    if (!(_1414 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1436 = vec2(dot(fa_mesh_fs_params[14], _1408), dot(fa_mesh_fs_params[15], _1408)) / vec2(_1414);\n    int _1440 = int(fa_mesh_fs_params[18].x);\n    int _1444 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1444) + clamp(int(floor(((_1436.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1444 - 1)) * _1440)) + clamp(int(floor(((_1436.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1440 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1520 = fa_cluster_texel(param);\n    return ivec2(int(_1520.x), int(_1520.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4337 = fa_cluster_lookup(param);\n    fa_cl_slot = _4337.x;\n    fa_cl_local = _4337.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4549 = fa_linear_to_srgb(param);\n        c = _4549;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4557 = fa_srgb_to_linear(param_1);\n            c = _4557;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _323;\n    if (i.front_facing)\n    {\n        _323 = i.world_normal;\n    }\n    else\n    {\n        _323 = -i.world_normal;\n    }\n    vec3 _347 = normalize(i.world_tangent.xyz - (_323 * dot(_323, i.world_tangent.xyz)));\n    vec3 _374 = normalize(((_347 * m.x) + ((cross(_323, _347) * i.world_tangent.w) * m.y)) + (_323 * m.z));\n    vec3 _377;\n    if (i.front_facing)\n    {\n        _377 = _374;\n    }\n    else\n    {\n        _377 = -_374;\n    }\n    return _377;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4588 = fa_tex_fix(param_2, param_3);\n    vec4 _5811 = base_t;\n    _5811.x = _4588.x;\n    _5811.y = _4588.y;\n    _5811.z = _4588.z;\n    base_t = _5811;\n    vec4 _4602 = (_5811 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5642 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4634 = fa_tex_fix(param_6, param_7);\n        vec3 _4637 = (_4634 * 2.0) - vec3(1.0);\n        vec2 _4642 = _4637.xy * fa_mesh_fs_params[6].x;\n        vec3 _5819 = _4637;\n        _5819.x = _4642.x;\n        _5819.y = _4642.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5819;\n        _5642 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4670 = fa_tex_fix(param_12, param_13);\n    vec4 _5822 = mrt;\n    _5822.x = _4670.x;\n    _5822.y = _4670.y;\n    _5822.z = _4670.z;\n    mrt = _5822;\n    vec4 _4698 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4698.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4709 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4739 = fa_tex_fix(param_20, param_21);\n    float _5647 = fa_mesh_fs_params[20].x;\n    float _5648 = fa_mesh_fs_params[20].y;\n    float _5651 = fa_mesh_fs_params[20].z;\n    float _5650 = fa_mesh_fs_params[21].w;\n    float _5653 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5647 *= _4709.y;\n            _5648 *= _4709.z;\n            _5650 *= _4698.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5651 *= mrt.x;\n            _5653 *= mrt.w;\n        }\n    }\n    return Surface(_4602.xyz, _4602.w, _5642, clamp(fa_mesh_fs_params[5].x * _4670.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4670.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4709.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4739), _5647, _5648, fa_mesh_fs_params[21].xyz, _5650, _5651, fa_mesh_fs_params[20].w, _5653, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1600 = rect.zw - rect.xy;\n    vec2 _1604 = _1600 * atlas;\n    vec2 _1608 = ddx * _1604;\n    vec2 _1612 = ddy * _1604;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1600), clamp(0.5 * log2(max(max(dot(_1608, _1608), dot(_1612, _1612)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1645 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1652;\n    if (!_1645)\n    {\n        _1652 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1652 = _1645;\n    }\n    if (_1652)\n    {\n        return;\n    }\n    vec3 _1658 = dFdx(world_pos);\n    vec3 _1661 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1665 = fa_cluster_texel(param);\n    int _1669 = int(_1665.w);\n    if (_1669 < 1)\n    {\n        return;\n    }\n    int _1679 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1679;\n    vec4 _1683 = fa_light_texel(param_1);\n    vec2 _1686 = _1683.yz;\n    int _1690 = int(_1683.w);\n    int param_2 = _1679 + 1;\n    vec4 _1695 = fa_light_texel(param_2);\n    float _1696 = _1695.x;\n    int _1702 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1706 = int(_1665.z);\n    vec3 _1971;\n    for (int k = 0; k < _1669; k++)\n    {\n        int _1719 = _1706 + k;\n        int param_3 = _1690 + (_1719 >> 2);\n        int _1736 = (_1679 + 2) + (int(fa_light_texel(param_3)[_1719 & 3]) * 7);\n        int param_4 = _1736 + 6;\n        vec4 _1741 = fa_light_texel(param_4);\n        if (((int(_1741.w + 0.5) >> _1702) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1736;\n        vec4 _1756 = fa_light_texel(param_5);\n        int param_6 = _1736 + 1;\n        vec4 _1761 = fa_light_texel(param_6);\n        int param_7 = _1736 + 2;\n        vec4 _1766 = fa_light_texel(param_7);\n        vec3 _1769 = _1756.xyz;\n        float _1774 = dot(_1769, world_pos) + _1756.w;\n        vec3 _1776 = _1761.xyz;\n        float _1781 = dot(_1776, world_pos) + _1761.w;\n        vec3 _1783 = _1766.xyz;\n        float _1788 = dot(_1783, world_pos) + _1766.w;\n        bool _1793 = abs(_1774) > 0.5;\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1781) > 0.5;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        bool _1809;\n        if (!_1801)\n        {\n            _1809 = abs(_1788) > 0.5;\n        }\n        else\n        {\n            _1809 = _1801;\n        }\n        if (_1809)\n        {\n            continue;\n        }\n        float _1824 = clamp(dot(geo_normal, normalize(_1783)) * _1741.z, 0.0, 1.0);\n        if (_1824 <= 0.0)\n        {\n            continue;\n        }\n        float _1844 = (clamp((0.5 - abs(_1788)) * 10.0, 0.0, 1.0) * _1824) * _1741.x;\n        vec2 _1852 = vec2(_1774 + 0.5, 0.5 - _1781);\n        vec2 _1862 = vec2(dot(_1769, _1658), dot(_1776, _1658));\n        vec2 _1872 = vec2(dot(_1769, _1661), dot(_1776, _1661));\n        int param_8 = _1736 + 5;\n        vec4 _1877 = fa_light_texel(param_8);\n        int param_9 = _1736 + 3;\n        vec4 _1882 = fa_light_texel(param_9);\n        int param_10 = _1736 + 4;\n        vec4 _1887 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1877.xyz;\n        bool _1897 = _1882.z > _1882.x;\n        if (_1897)\n        {\n            vec4 param_11 = _1882;\n            vec2 param_12 = _1852;\n            vec2 param_13 = _1686;\n            vec2 param_14 = _1862;\n            vec2 param_15 = _1872;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1696 > 0.5) && (_1696 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1923 = fa_dc_to_linear(param_16);\n                vec4 _5730 = tx;\n                _5730.x = _1923.x;\n                _5730.y = _1923.y;\n                _5730.z = _1923.z;\n                tx = _5730;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1844 * tex_a) * _1877.w, 0.0, 1.0)));\n        if (_1887.z > _1887.x)\n        {\n            vec4 param_17 = _1887;\n            vec2 param_18 = _1852;\n            vec2 param_19 = _1686;\n            vec2 param_20 = _1862;\n            vec2 param_21 = _1872;\n            vec4 _1967 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1696 > 1.5)\n            {\n                vec3 param_22 = _1967.xyz;\n                vec3 _1977 = fa_dc_to_srgb(param_22);\n                _1971 = _1977;\n            }\n            else\n            {\n                _1971 = _1967.xyz;\n            }\n            vec3 _1986 = (_1971 * 2.0) - vec3(1.0);\n            vec2 _1991 = _1986.xy * _1741.y;\n            vec3 _2013 = (normalize(_1769) * _1991.x) + (normalize(_1776) * _1991.y);\n            vec3 _2016 = normalize(normal);\n            normal = normalize(mix(_2016, normalize((_2016 * max(_1986.z, 0.0500000007450580596923828125)) + (_2013 - (_2016 * dot(_2016, _2013)))), vec3(clamp(_1844 * (_1897 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3211 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3211;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3454 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3461 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3464 = int(_3454);\n    int _3467 = int(_3461);\n    float _3477 = _3461 - float(_3467);\n    int _3532 = (_3464 * 9) + _3467;\n    int _3552 = ((_3464 + 1) * 9) + _3467;\n    return mix(mix(_3528[_3532], _3528[_3532 + 1], _3477), mix(_3528[_3552], _3528[_3552 + 1], _3477), _3454 - float(_3464));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5501 = false;\n    float _5502 = 1.0;\n    float _5503 = 1.0;\n    float _5504 = 1.0;\n    float _5505 = 0.0;\n    float _5506 = 0.0;\n    float _5507 = 0.0;\n    float _5508 = 0.0;\n    float _5510 = 1.0;\n    bool _5511 = false;\n    vec3 _5512 = vec3(0.0);\n    float _5513 = 1.0;\n    float _5514 = 1.0;\n    float _5515 = 1.0;\n    float _5516 = 0.0;\n    float _5517 = 0.0;\n    vec3 _5518 = vec3(1.0, 0.0, 0.0);\n    vec3 _5519 = vec3(0.0, 0.0, 1.0);\n    float _5520 = 1.0;\n    float _5521 = 1.0;\n    float _3603 = clamp(s.specular, 0.0, 1.0);\n    float _3607 = clamp(s.ior, 1.0, 3.0);\n    bool _3612 = (_3603 != 1.0) || (_3607 != 1.5);\n    bool _3621;\n    if (!_3612)\n    {\n        _3621 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3621 = _3612;\n    }\n    if (_3621)\n    {\n        float _3629 = (_3607 - 1.0) / (_3607 + 1.0);\n        f0 = mix(min(vec3(_3629 * _3629) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3603, s.albedo, vec3(metallic));\n        _5502 = mix(_3603, 1.0, metallic);\n        _5501 = true;\n    }\n    float _3656 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3656 > 0.0)\n    {\n        float _3664 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5505 = _3656;\n        _5506 = _3664;\n        float _3671 = _3664 * _3664;\n        _5507 = _3671;\n        _5508 = _3671 * _3671;\n        float _3683 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5510 = _3683;\n        _5503 = 1.0 - (_3656 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3683, 0.0, 1.0), 5.0))));\n        _5501 = true;\n    }\n    vec3 _3702 = max(s.sheen_color, vec3(0.0));\n    float _3711 = max(_3702.x, max(_3702.y, _3702.z));\n    if (_3711 > 0.0)\n    {\n        float _3719 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5511 = true;\n        _5512 = _3702;\n        _5513 = _3719;\n        _5514 = _3719 * _3719;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3719;\n        float _3736 = fa_sheen_albedo(param, param_1);\n        _5516 = _3736;\n        _5515 = 1.0 - min(_3711 * _3736, 1.0);\n        _5501 = true;\n    }\n    _5504 = _5503 * _5515;\n    float _3755 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3755 != 0.0)\n    {\n        vec3 _3770 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3770;\n        if (dot(_3770, _3770) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3782 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3782.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3782.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3782.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3786 = t;\n        vec3 _3787 = normalize(_3786);\n        t = _3787;\n        vec3 _3812 = normalize((_3787 * cos(s.anisotropy_rotation)) + ((cross(n, _3787) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5518 = _3812;\n        _5519 = cross(n, _3812);\n        float _3822 = roughness * roughness;\n        float _3828 = mix(_3822, 1.0, _3755 * _3755);\n        bool _3830 = _3755 > 0.0;\n        _5520 = _3830 ? _3828 : _3822;\n        _5521 = _3830 ? _3822 : _3828;\n        _5517 = _3755;\n        _5501 = true;\n    }\n    return FaLayers(_5501, _5502, _5503, _5504, _5505, _5506, _5507, _5508, i.world_normal, _5510, _5511, _5512, _5513, _5514, _5515, _5516, _5517, _5518, _5519, _5520, _5521);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3386 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3389 = _3386.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3389 * _3389, exp2((-9.27999973297119140625) * ndv)) * _3389) + _3386.y)) + _3386.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3240 = rough * rough;\n    float _3270 = 0.60000002384185791015625 * _3240;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3240)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3270, 0.0500000007450580596923828125 + _3270, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3240 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3863;\n        if (L.aniso >= 0.0)\n        {\n            _3863 = L.b;\n        }\n        else\n        {\n            _3863 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3863, v), _3863), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3896 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3896.x) + (vec3(L.f90) * _3896.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3951 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3951.x) + _3951.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3428 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3428.x) + vec3(_3428.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3980 = clamp(s.metallic, 0.0, 1.0);\n    float _3984 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3991 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3980));\n    vec3 f0 = _3991;\n    vec3 _3995 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3995;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3980;\n    float param_5 = _3984;\n    vec3 param_6 = _3991;\n    FaLayers _4012 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4012.on)\n    {\n        FaLayers param_7 = _4012;\n        vec3 param_8 = _3995;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3984;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3995;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3984;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4307;\n    if (fa_lm.z > 0.5)\n    {\n        _4307 = 0.0;\n    }\n    else\n    {\n        _4307 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4318 = _4307 < 1.0;\n    bool _4324;\n    if (_4318)\n    {\n        int param = li;\n        _4324 = fa_light_baked(param);\n    }\n    else\n    {\n        _4324 = _4318;\n    }\n    return _4324 ? _4307 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _619 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _632 = (c - (ru * hx)) - p;\n        vec3 _638 = ru * (2.0 * hx);\n        float _644 = max(dot(_638, _638), 9.9999999392252902907785028219223e-09);\n        float _648 = dot(_632, _638);\n        float t = clamp((-_648) / _644, 0.0, 1.0);\n        if (_619)\n        {\n            float _663 = dot(r, _638);\n            float _669 = _644 - (_663 * _663);\n            if (abs(_669) > (9.9999997473787516355514526367188e-06 * _644))\n            {\n                t = clamp(((dot(r, _632) * _663) - _648) / _669, 0.0, 1.0);\n            }\n        }\n        return (p + _632) + (_638 * t);\n    }\n    vec3 q = p;\n    float _701 = dot(r, axis);\n    bool _709;\n    if (_619)\n    {\n        _709 = abs(_701) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _709 = _619;\n    }\n    if (_709)\n    {\n        float _719 = dot(c - p, axis) / _701;\n        if (_719 > 0.0)\n        {\n            q = p + (r * _719);\n        }\n    }\n    vec3 _732 = q - c;\n    vec2 xy = vec2(dot(_732, ru), dot(_732, uu));\n    if (shape > 0.5)\n    {\n        float _747 = length(xy);\n        if (_747 > hx)\n        {\n            xy *= (hx / _747);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _539 = dot(d, right);\n    float _543 = dot(d, up);\n    float _554;\n    if (((_539 * _539) + (_543 * _543)) > 1.0000000133514319600180897396058e-10)\n    {\n        _554 = atan(_543, _539) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _554 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_554 - floor(_554)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _389 = abs(d);\n    float _391 = _389.x;\n    float _393 = _389.y;\n    bool _394 = _391 >= _393;\n    bool _402;\n    if (_394)\n    {\n        _402 = _391 >= _389.z;\n    }\n    else\n    {\n        _402 = _394;\n    }\n    int _403;\n    if (_402)\n    {\n        _403 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _418;\n        if (_393 >= _389.z)\n        {\n            _418 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _418 = (d.z > 0.0) ? 4 : 5;\n        }\n        _403 = _418;\n    }\n    return _403;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _785 = fa_light_base(param);\n    bool _789 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _785;\n    vec4 _793 = fa_light_texel(param_1);\n    int param_2 = _785 + 1;\n    vec4 _798 = fa_light_texel(param_2);\n    float _801 = _798.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _813 = _789 && (_801 > 2.5);\n    fa_light_is_area = _813;\n    bool _815 = _801 < 0.5;\n    vec3 l;\n    if (_815)\n    {\n        l = normalize(_793.xyz);\n        if (_789)\n        {\n            int param_3 = _785 + 6;\n            vec4 _829 = fa_light_texel(param_3);\n            if (_829.z > 0.5)\n            {\n                int param_4 = _785 + 4;\n                vec4 _839 = fa_light_texel(param_4);\n                int param_5 = _785 + 5;\n                vec4 _844 = fa_light_texel(param_5);\n                vec2 param_6 = _829.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _839.xyz) * _839.w, (-dot(world_pos, _844.xyz)) * _844.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _874 = _793.xyz;\n        vec3 _876 = _874 - world_pos;\n        vec3 to_light = _876;\n        float _879 = length(_876);\n        float reach = _879;\n        bool front = true;\n        if (_813)\n        {\n            int param_8 = _785 + 7;\n            reach = max(_879 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _785 + 4;\n            vec4 _903 = fa_light_texel(param_9);\n            int param_10 = _785 + 5;\n            vec4 _908 = fa_light_texel(param_10);\n            int param_11 = _785 + 6;\n            vec4 _913 = fa_light_texel(param_11);\n            float _914 = _913.w;\n            int param_12 = _785 + 2;\n            vec3 _921 = normalize(fa_light_texel(param_12).xyz);\n            bool _923 = _914 > 1.5;\n            bool _931;\n            if (!_923)\n            {\n                _931 = dot(_921, to_light) < 0.0;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            front = _931;\n            vec3 r = vec3(0.0);\n            vec3 _940 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _944 = dot(n, n) > 0.5;\n            bool _952;\n            if (_944)\n            {\n                _952 = dot(_940, _940) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _952 = _944;\n            }\n            if (_952)\n            {\n                r = reflect(-normalize(_940), normalize(n));\n            }\n            vec3 param_13 = _874;\n            vec3 param_14 = _921;\n            vec3 param_15 = _903.xyz;\n            vec3 param_16 = _908.xyz;\n            float param_17 = _903.w;\n            float param_18 = _908.w;\n            float param_19 = _914;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _988 = length(to_light);\n        dist = _988;\n        l = to_light / vec3(max(_988, 9.9999997473787516355514526367188e-05));\n        float _1002 = reach / max(_793.w, 0.001000000047497451305389404296875);\n        float _1008 = clamp(1.0 - (_1002 * _1002), 0.0, 1.0);\n        float _1010;\n        if (front)\n        {\n            _1010 = _1008 * _1008;\n        }\n        else\n        {\n            _1010 = 0.0;\n        }\n        atten = _1010;\n        bool _1021 = _801 < 2.5;\n        if ((_801 > 1.5) && _1021)\n        {\n            int param_22 = _785 + 2;\n            vec4 _1029 = fa_light_texel(param_22);\n            float _1039 = _1029.w;\n            int param_23 = _785 + 3;\n            vec4 _1044 = fa_light_texel(param_23);\n            float _1045 = _1044.x;\n            float cos_inner = _1045;\n            if (_1045 > 1.5)\n            {\n                cos_inner = mix(_1039, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1039, cos_inner, dot(-l, normalize(_1029.xyz)));\n        }\n        if (_789 && (_801 < 1.5))\n        {\n            int param_24 = _785 + 6;\n            vec4 _1069 = fa_light_texel(param_24);\n            if (_1069.z > 0.5)\n            {\n                vec3 _1077 = -to_light;\n                int param_25 = _785 + 4;\n                int param_26 = _785 + 5;\n                vec3 _1091 = fa_light_texel(param_25).xyz;\n                vec3 _1095 = fa_light_texel(param_26).xyz;\n                vec3 _1104 = vec3(dot(_1077, _1091), dot(_1077, _1095), dot(_1077, cross(_1091, _1095)));\n                vec3 param_27 = _1104;\n                int _1108 = fa_cube_face(param_27);\n                int param_28 = _1108;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1135 = vec2(dot(_1104, cross(param_29, param_30)), dot(_1104, param_30)) / vec2(max(dot(_1104, param_29), 9.9999997473787516355514526367188e-05));\n                int _1139 = _1108 / 3;\n                vec2 param_31 = _1069.xy + (vec2(float(_1108 - (_1139 * 3)), float(_1139)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1135.x), 0.5 - (0.5 * _1135.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _785 + 7;\n            vec4 _1169 = fa_light_texel(param_33);\n            if (_1169.z > 0.5)\n            {\n                int param_34 = _785 + 2;\n                int param_35 = _785 + 4;\n                int param_36 = _785 + 5;\n                vec2 param_37 = _1169.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_789 && _1021)\n            {\n                int param_42 = _785 + 6;\n                vec4 _1216 = fa_light_texel(param_42);\n                int param_43 = _785 + 7;\n                vec4 _1221 = fa_light_texel(param_43);\n                bool _1224 = _1216.z > 0.5;\n                bool _1231;\n                if (!_1224)\n                {\n                    _1231 = _1221.z > 0.5;\n                }\n                else\n                {\n                    _1231 = _1224;\n                }\n                if (_1231)\n                {\n                    int param_44 = _785 + 2;\n                    vec4 _1238 = fa_light_texel(param_44);\n                    vec3 _1242 = normalize(_1238.xyz);\n                    int param_45 = _785 + 4;\n                    vec4 _1247 = fa_light_texel(param_45);\n                    int param_46 = _785 + 5;\n                    vec4 _1252 = fa_light_texel(param_46);\n                    if (_1224)\n                    {\n                        vec3 _1260 = -to_light;\n                        float _1267 = _1238.w;\n                        float _1283 = 0.5 / max(dot(_1260, _1242) * (sqrt(max(1.0 - (_1267 * _1267), 0.0)) / max(_1267, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1216.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1260, _1247.xyz) * _1283), 0.5 - (dot(_1260, _1252.xyz) * _1283));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1221.z > 0.5)\n                    {\n                        vec2 param_49 = _1221.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1242;\n                        vec3 param_52 = _1247.xyz;\n                        vec3 param_53 = _1252.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5489 = _798.xyz * atten;\n    if (_789)\n    {\n        _5489 *= fa_light_tint;\n    }\n    int _1351;\n    if (_815)\n    {\n        _1351 = 0;\n    }\n    else\n    {\n        _1351 = ((_801 > 1.5) && (_801 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5489, atten, 1.0, dist, _1351);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2145 = fa_shadow_depth(param, param_1);\n    float _2149;\n    if (conv.x < 0.5)\n    {\n        _2149 = _2145;\n    }\n    else\n    {\n        _2149 = (conv.y * conv.z) / (conv.z - (_2145 * (conv.z - conv.y)));\n    }\n    return _2149;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2076 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2076), sin(_2076)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2195 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2204;\n        if (k < 0.0)\n        {\n            _2204 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        float _2224 = clamp((_2204 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2195;\n            vec2 _2243 = fa_shadow_vogel(param_3, param_4, param_5) * _2224;\n            vec2 param_6 = uv + (_2243 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2255 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2255 < (zr - (length(_2243) * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2281 = sum / cnt;\n        float _2291;\n        if (k < 0.0)\n        {\n            _2291 = (-k) / max(_2281, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2291 = k;\n        }\n        radius = clamp(((max(zr - _2281, 0.0) * unit) * _2291) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2313;\n        float param_11 = _2195;\n        vec2 _2332 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2332 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2332) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2532 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2539;\n    if (!_2532)\n    {\n        _2539 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2539 = _2532;\n    }\n    if (_2539)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2552 = fa_light_texel(param);\n    float _2553 = _2552.x;\n    if (_2553 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2562 = int(_2553 + 0.5);\n    int param_1 = _2562;\n    vec4 _2566 = fa_light_texel(param_1);\n    int param_2 = _2562 + 1;\n    vec4 _2571 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2574 = _2566.y;\n    if (_2574 > 0.0)\n    {\n        float _2591 = 1.0 - smoothstep(0.75 * _2574, _2574, length(world - fa_shadows[27].xyz));\n        fade = _2591;\n        if (_2591 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2566.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2615 = (_2562 + 2) + (face * 6);\n    int param_4 = _2615;\n    int param_5 = _2615 + 1;\n    int param_6 = _2615 + 3;\n    vec4 _2629 = fa_light_texel(param_6);\n    int param_7 = _2615 + 4;\n    vec4 _2634 = fa_light_texel(param_7);\n    int param_8 = _2615 + 5;\n    vec4 _2639 = fa_light_texel(param_8);\n    float _2651 = _2639.x * max(dot(_2629, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2656 = clamp(dot(n, l), 0.0, 1.0);\n    float _2679 = clamp(dot(n, _2629.xyz), -1.0, 1.0);\n    float _2698 = min(sqrt(1.0 - (_2679 * _2679)) / max(abs(dot(n, world - lpos)) / max(dot(_2629, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2701 = _2571.y;\n    float _2703;\n    if (_2701 > 0.0)\n    {\n        _2703 = _2701;\n    }\n    else\n    {\n        _2703 = 1.5 * _2651;\n    }\n    vec4 _2723 = vec4(world + (n * (_2703 * sqrt(1.0 - (_2656 * _2656)))), 1.0);\n    float _2727 = dot(_2629, _2723);\n    float _2730 = _2639.y;\n    if (_2727 < _2730)\n    {\n        return 1.0;\n    }\n    vec2 _2745 = vec2(dot(fa_light_texel(param_4), _2723), dot(fa_light_texel(param_5), _2723)) / vec2(_2727);\n    float _2747 = _2745.x;\n    bool _2750 = _2747 < _2634.x;\n    bool _2759;\n    if (!_2750)\n    {\n        _2759 = _2747 > _2634.z;\n    }\n    else\n    {\n        _2759 = _2750;\n    }\n    bool _2768;\n    if (!_2759)\n    {\n        _2768 = _2745.y < _2634.y;\n    }\n    else\n    {\n        _2768 = _2759;\n    }\n    bool _2777;\n    if (!_2768)\n    {\n        _2777 = _2745.y > _2634.w;\n    }\n    else\n    {\n        _2777 = _2768;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    float _2783 = _2571.x;\n    float _2785;\n    if (_2783 > 0.0)\n    {\n        _2785 = _2783;\n    }\n    else\n    {\n        _2785 = 1.5 * _2651;\n    }\n    vec2 param_9 = _2745;\n    vec4 param_10 = _2634;\n    float param_11 = _2727 - (_2785 * (1.0 + (0.5 * _2698)));\n    float param_12 = _2651;\n    float param_13 = 1.0;\n    float param_14 = _2639.z * 0.25;\n    float param_15 = (_2651 * min(_2698, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2730, _2639.z);\n    int param_17 = int(_2566.z + 0.5);\n    float param_18 = _2566.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2088;\n    if (i == 0)\n    {\n        _2088 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2104;\n        if (i == 1)\n        {\n            _2104 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2112;\n            if (i == 2)\n            {\n                _2112 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2112 = fa_shadows[24].w;\n            }\n            _2104 = _2112;\n        }\n        _2088 = _2104;\n    }\n    return _2088;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2374 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2379 = clamp(dot(n, l), 0.0, 1.0);\n    float _2385 = sqrt(1.0 - (_2379 * _2379));\n    float _2392 = min(_2385 / max(_2379, 0.20000000298023223876953125), 4.0);\n    float _2397;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2397 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2397 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2422 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2397 * _2385)), 1.0);\n    float _2429 = _2422.x;\n    bool _2432 = _2429 < fa_shadows[ci * 1 + 16].x;\n    bool _2441;\n    if (!_2432)\n    {\n        _2441 = _2429 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2441 = _2432;\n    }\n    bool _2450;\n    if (!_2441)\n    {\n        _2450 = _2422.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2450 = _2441;\n    }\n    bool _2459;\n    if (!_2450)\n    {\n        _2459 = _2422.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2459 = _2450;\n    }\n    bool _2466;\n    if (!_2459)\n    {\n        _2466 = _2422.z > 1.0;\n    }\n    else\n    {\n        _2466 = _2459;\n    }\n    if (_2466)\n    {\n        return -1.0;\n    }\n    float _2474;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2474 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2474 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2422.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2422.z - ((_2474 * (1.0 + (0.5 * _2392))) / _2374);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2392, 3.0)) * 0.5) / _2374;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2852 = int(fa_shadows[25].x + 0.5);\n    if (_2852 < 1)\n    {\n        return 1.0;\n    }\n    float _2867 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2852 - 1;\n    if (_2867 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2879 = _2852 > 1;\n    bool _2886;\n    if (_2879)\n    {\n        _2886 = _2867 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2886 = _2879;\n    }\n    if (_2886)\n    {\n        ci = 1;\n    }\n    bool _2890 = _2852 > 2;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2867 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 2;\n    }\n    bool _2901 = _2852 > 3;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2867 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2852)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2934;\n        if (_2934 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2959;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2959 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2959 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2978 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2989 = clamp((_2867 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0, 1.0);\n        if (_2989 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2852)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3010 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3010;\n                if (_3010 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2989);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4051 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4058;\n    if (!_4051)\n    {\n        _4058 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4058 = _4051;\n    }\n    if (_4058)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4071 = fa_light_texel(param);\n    float _4072 = _4071.y;\n    float len = _4072;\n    if (_4072 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4084 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4094 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4084);\n    if (_4094 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4100 = len;\n    float _4103 = min(_4100, 0.89999997615814208984375 * dist);\n    len = _4103;\n    float _4108 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4084);\n    float _4113 = _4108 + (0.5 * _4103);\n    vec3 _4119 = world + (gn * _4108);\n    float _4121 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4185;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4136 = (float(k) + _4121) * 0.083333335816860198974609375;\n        vec3 _4144 = _4119 + (l * (_4136 * len));\n        vec4 _4150 = vec4(_4144, 1.0);\n        float _4156 = dot(fa_mesh_fs_params[28], _4150);\n        if (_4156 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4176 = vec2(dot(fa_mesh_fs_params[26], _4150), dot(fa_mesh_fs_params[27], _4150)) / vec2(_4156);\n        float _4180 = _4176.x * 0.5;\n        float _4181 = _4180 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4185 = (_4176.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4185 = 0.5 - (_4176.y * 0.5);\n        }\n        bool _4201 = _4181 < 0.0;\n        bool _4208;\n        if (!_4201)\n        {\n            _4208 = _4181 >= 1.0;\n        }\n        else\n        {\n            _4208 = _4201;\n        }\n        bool _4215;\n        if (!_4208)\n        {\n            _4215 = _4185 < 0.0;\n        }\n        else\n        {\n            _4215 = _4208;\n        }\n        bool _4222;\n        if (!_4215)\n        {\n            _4222 = _4185 >= 1.0;\n        }\n        else\n        {\n            _4222 = _4215;\n        }\n        if (_4222)\n        {\n            break;\n        }\n        vec4 _4241 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4181, _4185) * fa_mesh_fs_params[24].zw), 0);\n        if (_4241.w < 0.5)\n        {\n            continue;\n        }\n        float _4260 = (dot(fa_mesh_fs_params[29].xyz, _4144) + fa_mesh_fs_params[29].w) - _4241.x;\n        if ((_4260 > _4108) && (_4260 < _4113))\n        {\n            occ = max(occ, (1.0 - (_4136 * _4136)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4181, 0.5 - _4180), min(_4185, 1.0 - _4185))));\n        }\n    }\n    return 1.0 - (occ * _4094);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4363 = fa_baked_keep(param);\n    if (_4363 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4389 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5622 = _4389.color;\n    float _5623 = _4389.attenuation;\n    float _5624 = _4389.shadow;\n    bool _4392 = _4389.type == 0;\n    if (_4392 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4389.direction;\n        float _4403 = fa_shadow_factor(param_5, param_6);\n        _5624 = _4403;\n        _5622 *= _4403;\n    }\n    else\n    {\n        bool _4414 = _4389.type != 0;\n        bool _4420;\n        if (_4414)\n        {\n            _4420 = _5623 > 0.0;\n        }\n        else\n        {\n            _4420 = _4414;\n        }\n        if (_4420)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4389.direction;\n            float _4439 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5624 = _4439;\n            _5622 *= _4439;\n        }\n    }\n    bool _4449 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4455;\n    if (_4449)\n    {\n        _4455 = _5623 > 0.0;\n    }\n    else\n    {\n        _4455 = _4449;\n    }\n    if (_4455)\n    {\n        float _4462;\n        if (_4392)\n        {\n            _4462 = 1000000000.0;\n        }\n        else\n        {\n            _4462 = _4389._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4389.direction;\n        float param_18 = _4462;\n        float _4480 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5624 *= _4480;\n        _5622 *= _4480;\n    }\n    float _4493 = _5623;\n    float _4494 = _4493 * _4363;\n    _5623 = _4494;\n    vec3 _4498 = _5622;\n    vec3 _4499 = _4498 * _4363;\n    _5622 = _4499;\n    return LightSample(_4389.direction, _4499, _4494, _5624, _4389._distance, _4389.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3034 = int(fa_shadows[25].x + 0.5);\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5307 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5307 = -_5307;\n    }\n    vec3 _4931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n    Surface _4939 = fa_standard_surface(param_1);\n    vec3 _5346 = _4939.albedo;\n    float _5347 = _4939.alpha;\n    vec3 _5348 = _4939.normal;\n    float _5349 = _4939.metallic;\n    float _5350 = _4939.roughness;\n    float _5351 = _4939.occlusion;\n    vec3 _5352 = _4939.emission;\n    float _5353 = _4939.clearcoat;\n    float _5354 = _4939.clearcoat_roughness;\n    vec3 _5355 = _4939.sheen_color;\n    float _5356 = _4939.sheen_roughness;\n    float _5357 = _4939.anisotropy;\n    float _5358 = _4939.anisotropy_rotation;\n    float _5359 = _4939.specular;\n    float _5360 = _4939.ior;\n    vec3 _5361 = _4939.specular_color;\n    float _5362 = _4939.transmission;\n    float _5363 = _4939.thickness;\n    vec3 _5364 = _4939.attenuation_color;\n    float _5365 = _4939.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n    Surface param_3 = _4939;\n    surface(param_2, param_3);\n    _5346 = param_3.albedo;\n    _5347 = param_3.alpha;\n    _5348 = param_3.normal;\n    _5349 = param_3.metallic;\n    _5350 = param_3.roughness;\n    _5351 = param_3.occlusion;\n    _5352 = param_3.emission;\n    _5353 = param_3.clearcoat;\n    _5354 = param_3.clearcoat_roughness;\n    _5355 = param_3.sheen_color;\n    _5356 = param_3.sheen_roughness;\n    _5357 = param_3.anisotropy;\n    _5358 = param_3.anisotropy_rotation;\n    _5359 = param_3.specular;\n    _5360 = param_3.ior;\n    _5361 = param_3.specular_color;\n    _5362 = param_3.transmission;\n    _5363 = param_3.thickness;\n    _5364 = param_3.attenuation_color;\n    _5365 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5307;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5346 = param_6;\n    _5348 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5346;\n    }\n    else\n    {\n        vec3 _4978 = _5348;\n        vec3 _4979 = normalize(_4978);\n        _5348 = _4979;\n        vec3 param_8 = _4979;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n        Surface param_10 = Surface(_5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4998 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4998; ln++)\n        {\n            int param_12 = ln;\n            int _5011 = fa_cl_light(param_12);\n            int param_13 = _5011;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5011;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5307;\n            LightSample _5027 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n            Surface param_18 = Surface(_5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365);\n            LightSample param_19 = _5027;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5042 = result;\n    vec3 _5043 = _5042 + _5352;\n    result = _5043;\n    vec3 param_20 = _5043;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5052 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5059;\n    if (!_5052)\n    {\n        _5059 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5059 = _5052;\n    }\n    if (_5059)\n    {\n        vec3 _5068 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5074 = dot(_5068, fa_mesh_fs_params[9].xyz);\n        bool _5078 = fa_mesh_fs_params[9].w > 0.5;\n        float _5079;\n        if (_5078)\n        {\n            _5079 = _5074;\n        }\n        else\n        {\n            _5079 = length(_5068);\n        }\n        float _5091 = _5079 - fa_mesh_fs_params[8].x;\n        if (_5091 > 0.0)\n        {\n            float _5100 = fa_mesh_fs_params[7].w * _5091;\n            float tau = _5100 * _5100;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5116;\n                if (_5078)\n                {\n                    _5116 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5074);\n                }\n                else\n                {\n                    _5116 = fa_mesh_fs_params[0].y;\n                }\n                float _5137 = mix(_5116, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5079, 0.0, 1.0));\n                float _5141 = fa_world_pos.y - _5137;\n                float _5146 = _5137 - fa_mesh_fs_params[8].z;\n                float _5151 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5154 = _5146 <= 0.0;\n                bool _5155 = !_5154;\n                bool _5161;\n                if (_5155)\n                {\n                    _5161 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5161 = _5154;\n                }\n                float _5162;\n                if (_5161)\n                {\n                    _5162 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5162 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5146, 80.0));\n                }\n                bool _5189;\n                if (_5155)\n                {\n                    _5189 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5189 = _5154;\n                }\n                float _5190;\n                if (_5189)\n                {\n                    _5190 = fa_mesh_fs_params[8].y * _5146;\n                }\n                else\n                {\n                    _5190 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5146, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5215 = _5151 <= 0.0;\n                bool _5222;\n                if (!_5215)\n                {\n                    _5222 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5222 = _5215;\n                }\n                float _5223;\n                if (_5222)\n                {\n                    _5223 = fa_mesh_fs_params[8].y * _5151;\n                }\n                else\n                {\n                    _5223 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5151, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5250;\n                if (abs(_5141) < 0.001000000047497451305389404296875)\n                {\n                    _5250 = _5162;\n                }\n                else\n                {\n                    _5250 = (_5223 - _5190) / _5141;\n                }\n                tau += (_5091 * max(_5250, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5347);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_441",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2098",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3528[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1369 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1376;\n    if (!_1369)\n    {\n        _1376 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1376 = _1369;\n    }\n    bool _1384;\n    if (!_1376)\n    {\n        _1384 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1384 = _1376;\n    }\n    bool _1391;\n    if (!_1384)\n    {\n        _1391 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1391 = _1384;\n    }\n    bool _1398;\n    if (!_1391)\n    {\n        _1398 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1398 = _1391;\n    }\n    if (_1398)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1408 = vec4(world_pos, 1.0);\n    float _1414 = dot(fa_mesh_fs_params[16], _1408);\n    if (!(_1414 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1436 = vec2(dot(fa_mesh_fs_params[14], _1408), dot(fa_mesh_fs_params[15], _1408)) / vec2(_1414);\n    int _1440 = int(fa_mesh_fs_params[18].x);\n    int _1444 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1444) + clamp(int(floor(((_1436.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1444 - 1)) * _1440)) + clamp(int(floor(((_1436.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1440 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1520 = fa_cluster_texel(param);\n    return ivec2(int(_1520.x), int(_1520.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4337 = fa_cluster_lookup(param);\n    fa_cl_slot = _4337.x;\n    fa_cl_local = _4337.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4549 = fa_linear_to_srgb(param);\n        c = _4549;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4557 = fa_srgb_to_linear(param_1);\n            c = _4557;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _323;\n    if (i.front_facing)\n    {\n        _323 = i.world_normal;\n    }\n    else\n    {\n        _323 = -i.world_normal;\n    }\n    vec3 _347 = normalize(i.world_tangent.xyz - (_323 * dot(_323, i.world_tangent.xyz)));\n    vec3 _374 = normalize(((_347 * m.x) + ((cross(_323, _347) * i.world_tangent.w) * m.y)) + (_323 * m.z));\n    vec3 _377;\n    if (i.front_facing)\n    {\n        _377 = _374;\n    }\n    else\n    {\n        _377 = -_374;\n    }\n    return _377;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4588 = fa_tex_fix(param_2, param_3);\n    vec4 _5811 = base_t;\n    _5811.x = _4588.x;\n    _5811.y = _4588.y;\n    _5811.z = _4588.z;\n    base_t = _5811;\n    vec4 _4602 = (_5811 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5642 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4634 = fa_tex_fix(param_6, param_7);\n        vec3 _4637 = (_4634 * 2.0) - vec3(1.0);\n        vec2 _4642 = _4637.xy * fa_mesh_fs_params[6].x;\n        vec3 _5819 = _4637;\n        _5819.x = _4642.x;\n        _5819.y = _4642.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5819;\n        _5642 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4670 = fa_tex_fix(param_12, param_13);\n    vec4 _5822 = mrt;\n    _5822.x = _4670.x;\n    _5822.y = _4670.y;\n    _5822.z = _4670.z;\n    mrt = _5822;\n    vec4 _4698 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4698.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4709 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4739 = fa_tex_fix(param_20, param_21);\n    float _5647 = fa_mesh_fs_params[20].x;\n    float _5648 = fa_mesh_fs_params[20].y;\n    float _5651 = fa_mesh_fs_params[20].z;\n    float _5650 = fa_mesh_fs_params[21].w;\n    float _5653 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5647 *= _4709.y;\n            _5648 *= _4709.z;\n            _5650 *= _4698.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5651 *= mrt.x;\n            _5653 *= mrt.w;\n        }\n    }\n    return Surface(_4602.xyz, _4602.w, _5642, clamp(fa_mesh_fs_params[5].x * _4670.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4670.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4709.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4739), _5647, _5648, fa_mesh_fs_params[21].xyz, _5650, _5651, fa_mesh_fs_params[20].w, _5653, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1600 = rect.zw - rect.xy;\n    vec2 _1604 = _1600 * atlas;\n    vec2 _1608 = ddx * _1604;\n    vec2 _1612 = ddy * _1604;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1600), clamp(0.5 * log2(max(max(dot(_1608, _1608), dot(_1612, _1612)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1645 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1652;\n    if (!_1645)\n    {\n        _1652 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1652 = _1645;\n    }\n    if (_1652)\n    {\n        return;\n    }\n    vec3 _1658 = dFdx(world_pos);\n    vec3 _1661 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1665 = fa_cluster_texel(param);\n    int _1669 = int(_1665.w);\n    if (_1669 < 1)\n    {\n        return;\n    }\n    int _1679 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1679;\n    vec4 _1683 = fa_light_texel(param_1);\n    vec2 _1686 = _1683.yz;\n    int _1690 = int(_1683.w);\n    int param_2 = _1679 + 1;\n    vec4 _1695 = fa_light_texel(param_2);\n    float _1696 = _1695.x;\n    int _1702 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1706 = int(_1665.z);\n    vec3 _1971;\n    for (int k = 0; k < _1669; k++)\n    {\n        int _1719 = _1706 + k;\n        int param_3 = _1690 + (_1719 >> 2);\n        int _1736 = (_1679 + 2) + (int(fa_light_texel(param_3)[_1719 & 3]) * 7);\n        int param_4 = _1736 + 6;\n        vec4 _1741 = fa_light_texel(param_4);\n        if (((int(_1741.w + 0.5) >> _1702) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1736;\n        vec4 _1756 = fa_light_texel(param_5);\n        int param_6 = _1736 + 1;\n        vec4 _1761 = fa_light_texel(param_6);\n        int param_7 = _1736 + 2;\n        vec4 _1766 = fa_light_texel(param_7);\n        vec3 _1769 = _1756.xyz;\n        float _1774 = dot(_1769, world_pos) + _1756.w;\n        vec3 _1776 = _1761.xyz;\n        float _1781 = dot(_1776, world_pos) + _1761.w;\n        vec3 _1783 = _1766.xyz;\n        float _1788 = dot(_1783, world_pos) + _1766.w;\n        bool _1793 = abs(_1774) > 0.5;\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1781) > 0.5;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        bool _1809;\n        if (!_1801)\n        {\n            _1809 = abs(_1788) > 0.5;\n        }\n        else\n        {\n            _1809 = _1801;\n        }\n        if (_1809)\n        {\n            continue;\n        }\n        float _1824 = clamp(dot(geo_normal, normalize(_1783)) * _1741.z, 0.0, 1.0);\n        if (_1824 <= 0.0)\n        {\n            continue;\n        }\n        float _1844 = (clamp((0.5 - abs(_1788)) * 10.0, 0.0, 1.0) * _1824) * _1741.x;\n        vec2 _1852 = vec2(_1774 + 0.5, 0.5 - _1781);\n        vec2 _1862 = vec2(dot(_1769, _1658), dot(_1776, _1658));\n        vec2 _1872 = vec2(dot(_1769, _1661), dot(_1776, _1661));\n        int param_8 = _1736 + 5;\n        vec4 _1877 = fa_light_texel(param_8);\n        int param_9 = _1736 + 3;\n        vec4 _1882 = fa_light_texel(param_9);\n        int param_10 = _1736 + 4;\n        vec4 _1887 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1877.xyz;\n        bool _1897 = _1882.z > _1882.x;\n        if (_1897)\n        {\n            vec4 param_11 = _1882;\n            vec2 param_12 = _1852;\n            vec2 param_13 = _1686;\n            vec2 param_14 = _1862;\n            vec2 param_15 = _1872;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1696 > 0.5) && (_1696 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1923 = fa_dc_to_linear(param_16);\n                vec4 _5730 = tx;\n                _5730.x = _1923.x;\n                _5730.y = _1923.y;\n                _5730.z = _1923.z;\n                tx = _5730;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1844 * tex_a) * _1877.w, 0.0, 1.0)));\n        if (_1887.z > _1887.x)\n        {\n            vec4 param_17 = _1887;\n            vec2 param_18 = _1852;\n            vec2 param_19 = _1686;\n            vec2 param_20 = _1862;\n            vec2 param_21 = _1872;\n            vec4 _1967 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1696 > 1.5)\n            {\n                vec3 param_22 = _1967.xyz;\n                vec3 _1977 = fa_dc_to_srgb(param_22);\n                _1971 = _1977;\n            }\n            else\n            {\n                _1971 = _1967.xyz;\n            }\n            vec3 _1986 = (_1971 * 2.0) - vec3(1.0);\n            vec2 _1991 = _1986.xy * _1741.y;\n            vec3 _2013 = (normalize(_1769) * _1991.x) + (normalize(_1776) * _1991.y);\n            vec3 _2016 = normalize(normal);\n            normal = normalize(mix(_2016, normalize((_2016 * max(_1986.z, 0.0500000007450580596923828125)) + (_2013 - (_2016 * dot(_2016, _2013)))), vec3(clamp(_1844 * (_1897 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3211 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3211;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3454 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3461 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3464 = int(_3454);\n    int _3467 = int(_3461);\n    float _3477 = _3461 - float(_3467);\n    int _3532 = (_3464 * 9) + _3467;\n    int _3552 = ((_3464 + 1) * 9) + _3467;\n    return mix(mix(_3528[_3532], _3528[_3532 + 1], _3477), mix(_3528[_3552], _3528[_3552 + 1], _3477), _3454 - float(_3464));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5501 = false;\n    float _5502 = 1.0;\n    float _5503 = 1.0;\n    float _5504 = 1.0;\n    float _5505 = 0.0;\n    float _5506 = 0.0;\n    float _5507 = 0.0;\n    float _5508 = 0.0;\n    float _5510 = 1.0;\n    bool _5511 = false;\n    vec3 _5512 = vec3(0.0);\n    float _5513 = 1.0;\n    float _5514 = 1.0;\n    float _5515 = 1.0;\n    float _5516 = 0.0;\n    float _5517 = 0.0;\n    vec3 _5518 = vec3(1.0, 0.0, 0.0);\n    vec3 _5519 = vec3(0.0, 0.0, 1.0);\n    float _5520 = 1.0;\n    float _5521 = 1.0;\n    float _3603 = clamp(s.specular, 0.0, 1.0);\n    float _3607 = clamp(s.ior, 1.0, 3.0);\n    bool _3612 = (_3603 != 1.0) || (_3607 != 1.5);\n    bool _3621;\n    if (!_3612)\n    {\n        _3621 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3621 = _3612;\n    }\n    if (_3621)\n    {\n        float _3629 = (_3607 - 1.0) / (_3607 + 1.0);\n        f0 = mix(min(vec3(_3629 * _3629) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3603, s.albedo, vec3(metallic));\n        _5502 = mix(_3603, 1.0, metallic);\n        _5501 = true;\n    }\n    float _3656 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3656 > 0.0)\n    {\n        float _3664 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5505 = _3656;\n        _5506 = _3664;\n        float _3671 = _3664 * _3664;\n        _5507 = _3671;\n        _5508 = _3671 * _3671;\n        float _3683 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5510 = _3683;\n        _5503 = 1.0 - (_3656 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3683, 0.0, 1.0), 5.0))));\n        _5501 = true;\n    }\n    vec3 _3702 = max(s.sheen_color, vec3(0.0));\n    float _3711 = max(_3702.x, max(_3702.y, _3702.z));\n    if (_3711 > 0.0)\n    {\n        float _3719 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5511 = true;\n        _5512 = _3702;\n        _5513 = _3719;\n        _5514 = _3719 * _3719;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3719;\n        float _3736 = fa_sheen_albedo(param, param_1);\n        _5516 = _3736;\n        _5515 = 1.0 - min(_3711 * _3736, 1.0);\n        _5501 = true;\n    }\n    _5504 = _5503 * _5515;\n    float _3755 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3755 != 0.0)\n    {\n        vec3 _3770 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3770;\n        if (dot(_3770, _3770) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3782 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3782.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3782.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3782.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3786 = t;\n        vec3 _3787 = normalize(_3786);\n        t = _3787;\n        vec3 _3812 = normalize((_3787 * cos(s.anisotropy_rotation)) + ((cross(n, _3787) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5518 = _3812;\n        _5519 = cross(n, _3812);\n        float _3822 = roughness * roughness;\n        float _3828 = mix(_3822, 1.0, _3755 * _3755);\n        bool _3830 = _3755 > 0.0;\n        _5520 = _3830 ? _3828 : _3822;\n        _5521 = _3830 ? _3822 : _3828;\n        _5517 = _3755;\n        _5501 = true;\n    }\n    return FaLayers(_5501, _5502, _5503, _5504, _5505, _5506, _5507, _5508, i.world_normal, _5510, _5511, _5512, _5513, _5514, _5515, _5516, _5517, _5518, _5519, _5520, _5521);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3386 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3389 = _3386.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3389 * _3389, exp2((-9.27999973297119140625) * ndv)) * _3389) + _3386.y)) + _3386.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3240 = rough * rough;\n    float _3270 = 0.60000002384185791015625 * _3240;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3240)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3270, 0.0500000007450580596923828125 + _3270, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3240 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3863;\n        if (L.aniso >= 0.0)\n        {\n            _3863 = L.b;\n        }\n        else\n        {\n            _3863 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3863, v), _3863), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3896 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3896.x) + (vec3(L.f90) * _3896.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3951 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3951.x) + _3951.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3428 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3428.x) + vec3(_3428.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3980 = clamp(s.metallic, 0.0, 1.0);\n    float _3984 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3991 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3980));\n    vec3 f0 = _3991;\n    vec3 _3995 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3995;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3980;\n    float param_5 = _3984;\n    vec3 param_6 = _3991;\n    FaLayers _4012 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4012.on)\n    {\n        FaLayers param_7 = _4012;\n        vec3 param_8 = _3995;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3984;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3995;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3984;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4307;\n    if (fa_lm.z > 0.5)\n    {\n        _4307 = 0.0;\n    }\n    else\n    {\n        _4307 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4318 = _4307 < 1.0;\n    bool _4324;\n    if (_4318)\n    {\n        int param = li;\n        _4324 = fa_light_baked(param);\n    }\n    else\n    {\n        _4324 = _4318;\n    }\n    return _4324 ? _4307 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _619 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _632 = (c - (ru * hx)) - p;\n        vec3 _638 = ru * (2.0 * hx);\n        float _644 = max(dot(_638, _638), 9.9999999392252902907785028219223e-09);\n        float _648 = dot(_632, _638);\n        float t = clamp((-_648) / _644, 0.0, 1.0);\n        if (_619)\n        {\n            float _663 = dot(r, _638);\n            float _669 = _644 - (_663 * _663);\n            if (abs(_669) > (9.9999997473787516355514526367188e-06 * _644))\n            {\n                t = clamp(((dot(r, _632) * _663) - _648) / _669, 0.0, 1.0);\n            }\n        }\n        return (p + _632) + (_638 * t);\n    }\n    vec3 q = p;\n    float _701 = dot(r, axis);\n    bool _709;\n    if (_619)\n    {\n        _709 = abs(_701) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _709 = _619;\n    }\n    if (_709)\n    {\n        float _719 = dot(c - p, axis) / _701;\n        if (_719 > 0.0)\n        {\n            q = p + (r * _719);\n        }\n    }\n    vec3 _732 = q - c;\n    vec2 xy = vec2(dot(_732, ru), dot(_732, uu));\n    if (shape > 0.5)\n    {\n        float _747 = length(xy);\n        if (_747 > hx)\n        {\n            xy *= (hx / _747);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _539 = dot(d, right);\n    float _543 = dot(d, up);\n    float _554;\n    if (((_539 * _539) + (_543 * _543)) > 1.0000000133514319600180897396058e-10)\n    {\n        _554 = atan(_543, _539) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _554 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_554 - floor(_554)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _389 = abs(d);\n    float _391 = _389.x;\n    float _393 = _389.y;\n    bool _394 = _391 >= _393;\n    bool _402;\n    if (_394)\n    {\n        _402 = _391 >= _389.z;\n    }\n    else\n    {\n        _402 = _394;\n    }\n    int _403;\n    if (_402)\n    {\n        _403 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _418;\n        if (_393 >= _389.z)\n        {\n            _418 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _418 = (d.z > 0.0) ? 4 : 5;\n        }\n        _403 = _418;\n    }\n    return _403;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _785 = fa_light_base(param);\n    bool _789 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _785;\n    vec4 _793 = fa_light_texel(param_1);\n    int param_2 = _785 + 1;\n    vec4 _798 = fa_light_texel(param_2);\n    float _801 = _798.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _813 = _789 && (_801 > 2.5);\n    fa_light_is_area = _813;\n    bool _815 = _801 < 0.5;\n    vec3 l;\n    if (_815)\n    {\n        l = normalize(_793.xyz);\n        if (_789)\n        {\n            int param_3 = _785 + 6;\n            vec4 _829 = fa_light_texel(param_3);\n            if (_829.z > 0.5)\n            {\n                int param_4 = _785 + 4;\n                vec4 _839 = fa_light_texel(param_4);\n                int param_5 = _785 + 5;\n                vec4 _844 = fa_light_texel(param_5);\n                vec2 param_6 = _829.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _839.xyz) * _839.w, (-dot(world_pos, _844.xyz)) * _844.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _874 = _793.xyz;\n        vec3 _876 = _874 - world_pos;\n        vec3 to_light = _876;\n        float _879 = length(_876);\n        float reach = _879;\n        bool front = true;\n        if (_813)\n        {\n            int param_8 = _785 + 7;\n            reach = max(_879 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _785 + 4;\n            vec4 _903 = fa_light_texel(param_9);\n            int param_10 = _785 + 5;\n            vec4 _908 = fa_light_texel(param_10);\n            int param_11 = _785 + 6;\n            vec4 _913 = fa_light_texel(param_11);\n            float _914 = _913.w;\n            int param_12 = _785 + 2;\n            vec3 _921 = normalize(fa_light_texel(param_12).xyz);\n            bool _923 = _914 > 1.5;\n            bool _931;\n            if (!_923)\n            {\n                _931 = dot(_921, to_light) < 0.0;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            front = _931;\n            vec3 r = vec3(0.0);\n            vec3 _940 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _944 = dot(n, n) > 0.5;\n            bool _952;\n            if (_944)\n            {\n                _952 = dot(_940, _940) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _952 = _944;\n            }\n            if (_952)\n            {\n                r = reflect(-normalize(_940), normalize(n));\n            }\n            vec3 param_13 = _874;\n            vec3 param_14 = _921;\n            vec3 param_15 = _903.xyz;\n            vec3 param_16 = _908.xyz;\n            float param_17 = _903.w;\n            float param_18 = _908.w;\n            float param_19 = _914;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _988 = length(to_light);\n        dist = _988;\n        l = to_light / vec3(max(_988, 9.9999997473787516355514526367188e-05));\n        float _1002 = reach / max(_793.w, 0.001000000047497451305389404296875);\n        float _1008 = clamp(1.0 - (_1002 * _1002), 0.0, 1.0);\n        float _1010;\n        if (front)\n        {\n            _1010 = _1008 * _1008;\n        }\n        else\n        {\n            _1010 = 0.0;\n        }\n        atten = _1010;\n        bool _1021 = _801 < 2.5;\n        if ((_801 > 1.5) && _1021)\n        {\n            int param_22 = _785 + 2;\n            vec4 _1029 = fa_light_texel(param_22);\n            float _1039 = _1029.w;\n            int param_23 = _785 + 3;\n            vec4 _1044 = fa_light_texel(param_23);\n            float _1045 = _1044.x;\n            float cos_inner = _1045;\n            if (_1045 > 1.5)\n            {\n                cos_inner = mix(_1039, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1039, cos_inner, dot(-l, normalize(_1029.xyz)));\n        }\n        if (_789 && (_801 < 1.5))\n        {\n            int param_24 = _785 + 6;\n            vec4 _1069 = fa_light_texel(param_24);\n            if (_1069.z > 0.5)\n            {\n                vec3 _1077 = -to_light;\n                int param_25 = _785 + 4;\n                int param_26 = _785 + 5;\n                vec3 _1091 = fa_light_texel(param_25).xyz;\n                vec3 _1095 = fa_light_texel(param_26).xyz;\n                vec3 _1104 = vec3(dot(_1077, _1091), dot(_1077, _1095), dot(_1077, cross(_1091, _1095)));\n                vec3 param_27 = _1104;\n                int _1108 = fa_cube_face(param_27);\n                int param_28 = _1108;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1135 = vec2(dot(_1104, cross(param_29, param_30)), dot(_1104, param_30)) / vec2(max(dot(_1104, param_29), 9.9999997473787516355514526367188e-05));\n                int _1139 = _1108 / 3;\n                vec2 param_31 = _1069.xy + (vec2(float(_1108 - (_1139 * 3)), float(_1139)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1135.x), 0.5 - (0.5 * _1135.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _785 + 7;\n            vec4 _1169 = fa_light_texel(param_33);\n            if (_1169.z > 0.5)\n            {\n                int param_34 = _785 + 2;\n                int param_35 = _785 + 4;\n                int param_36 = _785 + 5;\n                vec2 param_37 = _1169.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_789 && _1021)\n            {\n                int param_42 = _785 + 6;\n                vec4 _1216 = fa_light_texel(param_42);\n                int param_43 = _785 + 7;\n                vec4 _1221 = fa_light_texel(param_43);\n                bool _1224 = _1216.z > 0.5;\n                bool _1231;\n                if (!_1224)\n                {\n                    _1231 = _1221.z > 0.5;\n                }\n                else\n                {\n                    _1231 = _1224;\n                }\n                if (_1231)\n                {\n                    int param_44 = _785 + 2;\n                    vec4 _1238 = fa_light_texel(param_44);\n                    vec3 _1242 = normalize(_1238.xyz);\n                    int param_45 = _785 + 4;\n                    vec4 _1247 = fa_light_texel(param_45);\n                    int param_46 = _785 + 5;\n                    vec4 _1252 = fa_light_texel(param_46);\n                    if (_1224)\n                    {\n                        vec3 _1260 = -to_light;\n                        float _1267 = _1238.w;\n                        float _1283 = 0.5 / max(dot(_1260, _1242) * (sqrt(max(1.0 - (_1267 * _1267), 0.0)) / max(_1267, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1216.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1260, _1247.xyz) * _1283), 0.5 - (dot(_1260, _1252.xyz) * _1283));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1221.z > 0.5)\n                    {\n                        vec2 param_49 = _1221.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1242;\n                        vec3 param_52 = _1247.xyz;\n                        vec3 param_53 = _1252.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5489 = _798.xyz * atten;\n    if (_789)\n    {\n        _5489 *= fa_light_tint;\n    }\n    int _1351;\n    if (_815)\n    {\n        _1351 = 0;\n    }\n    else\n    {\n        _1351 = ((_801 > 1.5) && (_801 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5489, atten, 1.0, dist, _1351);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2145 = fa_shadow_depth(param, param_1);\n    float _2149;\n    if (conv.x < 0.5)\n    {\n        _2149 = _2145;\n    }\n    else\n    {\n        _2149 = (conv.y * conv.z) / (conv.z - (_2145 * (conv.z - conv.y)));\n    }\n    return _2149;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2076 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2076), sin(_2076)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2195 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2204;\n        if (k < 0.0)\n        {\n            _2204 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2204 = k;\n        }\n        float _2224 = clamp((_2204 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2195;\n            vec2 _2243 = fa_shadow_vogel(param_3, param_4, param_5) * _2224;\n            vec2 param_6 = uv + (_2243 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2255 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2255 < (zr - (length(_2243) * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2281 = sum / cnt;\n        float _2291;\n        if (k < 0.0)\n        {\n            _2291 = (-k) / max(_2281, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2291 = k;\n        }\n        radius = clamp(((max(zr - _2281, 0.0) * unit) * _2291) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2313;\n        float param_11 = _2195;\n        vec2 _2332 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2332 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2332) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2532 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2539;\n    if (!_2532)\n    {\n        _2539 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2539 = _2532;\n    }\n    if (_2539)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2552 = fa_light_texel(param);\n    float _2553 = _2552.x;\n    if (_2553 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2562 = int(_2553 + 0.5);\n    int param_1 = _2562;\n    vec4 _2566 = fa_light_texel(param_1);\n    int param_2 = _2562 + 1;\n    vec4 _2571 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2574 = _2566.y;\n    if (_2574 > 0.0)\n    {\n        float _2591 = 1.0 - smoothstep(0.75 * _2574, _2574, length(world - fa_shadows[27].xyz));\n        fade = _2591;\n        if (_2591 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2566.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2615 = (_2562 + 2) + (face * 6);\n    int param_4 = _2615;\n    int param_5 = _2615 + 1;\n    int param_6 = _2615 + 3;\n    vec4 _2629 = fa_light_texel(param_6);\n    int param_7 = _2615 + 4;\n    vec4 _2634 = fa_light_texel(param_7);\n    int param_8 = _2615 + 5;\n    vec4 _2639 = fa_light_texel(param_8);\n    float _2651 = _2639.x * max(dot(_2629, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2656 = clamp(dot(n, l), 0.0, 1.0);\n    float _2679 = clamp(dot(n, _2629.xyz), -1.0, 1.0);\n    float _2698 = min(sqrt(1.0 - (_2679 * _2679)) / max(abs(dot(n, world - lpos)) / max(dot(_2629, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2701 = _2571.y;\n    float _2703;\n    if (_2701 > 0.0)\n    {\n        _2703 = _2701;\n    }\n    else\n    {\n        _2703 = 1.5 * _2651;\n    }\n    vec4 _2723 = vec4(world + (n * (_2703 * sqrt(1.0 - (_2656 * _2656)))), 1.0);\n    float _2727 = dot(_2629, _2723);\n    float _2730 = _2639.y;\n    if (_2727 < _2730)\n    {\n        return 1.0;\n    }\n    vec2 _2745 = vec2(dot(fa_light_texel(param_4), _2723), dot(fa_light_texel(param_5), _2723)) / vec2(_2727);\n    float _2747 = _2745.x;\n    bool _2750 = _2747 < _2634.x;\n    bool _2759;\n    if (!_2750)\n    {\n        _2759 = _2747 > _2634.z;\n    }\n    else\n    {\n        _2759 = _2750;\n    }\n    bool _2768;\n    if (!_2759)\n    {\n        _2768 = _2745.y < _2634.y;\n    }\n    else\n    {\n        _2768 = _2759;\n    }\n    bool _2777;\n    if (!_2768)\n    {\n        _2777 = _2745.y > _2634.w;\n    }\n    else\n    {\n        _2777 = _2768;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    float _2783 = _2571.x;\n    float _2785;\n    if (_2783 > 0.0)\n    {\n        _2785 = _2783;\n    }\n    else\n    {\n        _2785 = 1.5 * _2651;\n    }\n    vec2 param_9 = _2745;\n    vec4 param_10 = _2634;\n    float param_11 = _2727 - (_2785 * (1.0 + (0.5 * _2698)));\n    float param_12 = _2651;\n    float param_13 = 1.0;\n    float param_14 = _2639.z * 0.25;\n    float param_15 = (_2651 * min(_2698, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2730, _2639.z);\n    int param_17 = int(_2566.z + 0.5);\n    float param_18 = _2566.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2088;\n    if (i == 0)\n    {\n        _2088 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2104;\n        if (i == 1)\n        {\n            _2104 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2112;\n            if (i == 2)\n            {\n                _2112 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2112 = fa_shadows[24].w;\n            }\n            _2104 = _2112;\n        }\n        _2088 = _2104;\n    }\n    return _2088;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2374 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2379 = clamp(dot(n, l), 0.0, 1.0);\n    float _2385 = sqrt(1.0 - (_2379 * _2379));\n    float _2392 = min(_2385 / max(_2379, 0.20000000298023223876953125), 4.0);\n    float _2397;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2397 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2397 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2422 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2397 * _2385)), 1.0);\n    float _2429 = _2422.x;\n    bool _2432 = _2429 < fa_shadows[ci * 1 + 16].x;\n    bool _2441;\n    if (!_2432)\n    {\n        _2441 = _2429 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2441 = _2432;\n    }\n    bool _2450;\n    if (!_2441)\n    {\n        _2450 = _2422.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2450 = _2441;\n    }\n    bool _2459;\n    if (!_2450)\n    {\n        _2459 = _2422.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2459 = _2450;\n    }\n    bool _2466;\n    if (!_2459)\n    {\n        _2466 = _2422.z > 1.0;\n    }\n    else\n    {\n        _2466 = _2459;\n    }\n    if (_2466)\n    {\n        return -1.0;\n    }\n    float _2474;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2474 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2474 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2422.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2422.z - ((_2474 * (1.0 + (0.5 * _2392))) / _2374);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2392, 3.0)) * 0.5) / _2374;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2852 = int(fa_shadows[25].x + 0.5);\n    if (_2852 < 1)\n    {\n        return 1.0;\n    }\n    float _2867 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2852 - 1;\n    if (_2867 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2879 = _2852 > 1;\n    bool _2886;\n    if (_2879)\n    {\n        _2886 = _2867 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2886 = _2879;\n    }\n    if (_2886)\n    {\n        ci = 1;\n    }\n    bool _2890 = _2852 > 2;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2867 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 2;\n    }\n    bool _2901 = _2852 > 3;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2867 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2852)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2934;\n        if (_2934 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2959;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2959 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2959 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2978 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2989 = clamp((_2867 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0, 1.0);\n        if (_2989 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2852)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3010 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3010;\n                if (_3010 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2989);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4051 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4058;\n    if (!_4051)\n    {\n        _4058 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4058 = _4051;\n    }\n    if (_4058)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4071 = fa_light_texel(param);\n    float _4072 = _4071.y;\n    float len = _4072;\n    if (_4072 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4084 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4094 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4084);\n    if (_4094 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4100 = len;\n    float _4103 = min(_4100, 0.89999997615814208984375 * dist);\n    len = _4103;\n    float _4108 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4084);\n    float _4113 = _4108 + (0.5 * _4103);\n    vec3 _4119 = world + (gn * _4108);\n    float _4121 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4185;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4136 = (float(k) + _4121) * 0.083333335816860198974609375;\n        vec3 _4144 = _4119 + (l * (_4136 * len));\n        vec4 _4150 = vec4(_4144, 1.0);\n        float _4156 = dot(fa_mesh_fs_params[28], _4150);\n        if (_4156 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4176 = vec2(dot(fa_mesh_fs_params[26], _4150), dot(fa_mesh_fs_params[27], _4150)) / vec2(_4156);\n        float _4180 = _4176.x * 0.5;\n        float _4181 = _4180 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4185 = (_4176.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4185 = 0.5 - (_4176.y * 0.5);\n        }\n        bool _4201 = _4181 < 0.0;\n        bool _4208;\n        if (!_4201)\n        {\n            _4208 = _4181 >= 1.0;\n        }\n        else\n        {\n            _4208 = _4201;\n        }\n        bool _4215;\n        if (!_4208)\n        {\n            _4215 = _4185 < 0.0;\n        }\n        else\n        {\n            _4215 = _4208;\n        }\n        bool _4222;\n        if (!_4215)\n        {\n            _4222 = _4185 >= 1.0;\n        }\n        else\n        {\n            _4222 = _4215;\n        }\n        if (_4222)\n        {\n            break;\n        }\n        vec4 _4241 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4181, _4185) * fa_mesh_fs_params[24].zw), 0);\n        if (_4241.w < 0.5)\n        {\n            continue;\n        }\n        float _4260 = (dot(fa_mesh_fs_params[29].xyz, _4144) + fa_mesh_fs_params[29].w) - _4241.x;\n        if ((_4260 > _4108) && (_4260 < _4113))\n        {\n            occ = max(occ, (1.0 - (_4136 * _4136)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4181, 0.5 - _4180), min(_4185, 1.0 - _4185))));\n        }\n    }\n    return 1.0 - (occ * _4094);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4363 = fa_baked_keep(param);\n    if (_4363 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4389 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5622 = _4389.color;\n    float _5623 = _4389.attenuation;\n    float _5624 = _4389.shadow;\n    bool _4392 = _4389.type == 0;\n    if (_4392 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4389.direction;\n        float _4403 = fa_shadow_factor(param_5, param_6);\n        _5624 = _4403;\n        _5622 *= _4403;\n    }\n    else\n    {\n        bool _4414 = _4389.type != 0;\n        bool _4420;\n        if (_4414)\n        {\n            _4420 = _5623 > 0.0;\n        }\n        else\n        {\n            _4420 = _4414;\n        }\n        if (_4420)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4389.direction;\n            float _4439 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5624 = _4439;\n            _5622 *= _4439;\n        }\n    }\n    bool _4449 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4455;\n    if (_4449)\n    {\n        _4455 = _5623 > 0.0;\n    }\n    else\n    {\n        _4455 = _4449;\n    }\n    if (_4455)\n    {\n        float _4462;\n        if (_4392)\n        {\n            _4462 = 1000000000.0;\n        }\n        else\n        {\n            _4462 = _4389._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4389.direction;\n        float param_18 = _4462;\n        float _4480 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5624 *= _4480;\n        _5622 *= _4480;\n    }\n    float _4493 = _5623;\n    float _4494 = _4493 * _4363;\n    _5623 = _4494;\n    vec3 _4498 = _5622;\n    vec3 _4499 = _4498 * _4363;\n    _5622 = _4499;\n    return LightSample(_4389.direction, _4499, _4494, _5624, _4389._distance, _4389.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3034 = int(fa_shadows[25].x + 0.5);\n    float _3044 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5307 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5307 = -_5307;\n    }\n    vec3 _4931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n    Surface _4939 = fa_standard_surface(param_1);\n    vec3 _5346 = _4939.albedo;\n    float _5347 = _4939.alpha;\n    vec3 _5348 = _4939.normal;\n    float _5349 = _4939.metallic;\n    float _5350 = _4939.roughness;\n    float _5351 = _4939.occlusion;\n    vec3 _5352 = _4939.emission;\n    float _5353 = _4939.clearcoat;\n    float _5354 = _4939.clearcoat_roughness;\n    vec3 _5355 = _4939.sheen_color;\n    float _5356 = _4939.sheen_roughness;\n    float _5357 = _4939.anisotropy;\n    float _5358 = _4939.anisotropy_rotation;\n    float _5359 = _4939.specular;\n    float _5360 = _4939.ior;\n    vec3 _5361 = _4939.specular_color;\n    float _5362 = _4939.transmission;\n    float _5363 = _4939.thickness;\n    vec3 _5364 = _4939.attenuation_color;\n    float _5365 = _4939.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n    Surface param_3 = _4939;\n    surface(param_2, param_3);\n    _5346 = param_3.albedo;\n    _5347 = param_3.alpha;\n    _5348 = param_3.normal;\n    _5349 = param_3.metallic;\n    _5350 = param_3.roughness;\n    _5351 = param_3.occlusion;\n    _5352 = param_3.emission;\n    _5353 = param_3.clearcoat;\n    _5354 = param_3.clearcoat_roughness;\n    _5355 = param_3.sheen_color;\n    _5356 = param_3.sheen_roughness;\n    _5357 = param_3.anisotropy;\n    _5358 = param_3.anisotropy_rotation;\n    _5359 = param_3.specular;\n    _5360 = param_3.ior;\n    _5361 = param_3.specular_color;\n    _5362 = param_3.transmission;\n    _5363 = param_3.thickness;\n    _5364 = param_3.attenuation_color;\n    _5365 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5307;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5346 = param_6;\n    _5348 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5346;\n    }\n    else\n    {\n        vec3 _4978 = _5348;\n        vec3 _4979 = normalize(_4978);\n        _5348 = _4979;\n        vec3 param_8 = _4979;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n        Surface param_10 = Surface(_5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _4998 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4998; ln++)\n        {\n            int param_12 = ln;\n            int _5011 = fa_cl_light(param_12);\n            int param_13 = _5011;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _5011;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _5307;\n            LightSample _5027 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _5307, fa_world_tangent, fa_uv, fa_vertex_color, _4931, gl_FrontFacing);\n            Surface param_18 = Surface(_5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, _5361, _5362, _5363, _5364, _5365);\n            LightSample param_19 = _5027;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _5042 = result;\n    vec3 _5043 = _5042 + _5352;\n    result = _5043;\n    vec3 param_20 = _5043;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5052 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5059;\n    if (!_5052)\n    {\n        _5059 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5059 = _5052;\n    }\n    if (_5059)\n    {\n        vec3 _5068 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5074 = dot(_5068, fa_mesh_fs_params[9].xyz);\n        bool _5078 = fa_mesh_fs_params[9].w > 0.5;\n        float _5079;\n        if (_5078)\n        {\n            _5079 = _5074;\n        }\n        else\n        {\n            _5079 = length(_5068);\n        }\n        float _5091 = _5079 - fa_mesh_fs_params[8].x;\n        if (_5091 > 0.0)\n        {\n            float _5100 = fa_mesh_fs_params[7].w * _5091;\n            float tau = _5100 * _5100;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5116;\n                if (_5078)\n                {\n                    _5116 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5074);\n                }\n                else\n                {\n                    _5116 = fa_mesh_fs_params[0].y;\n                }\n                float _5137 = mix(_5116, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5079, 0.0, 1.0));\n                float _5141 = fa_world_pos.y - _5137;\n                float _5146 = _5137 - fa_mesh_fs_params[8].z;\n                float _5151 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5154 = _5146 <= 0.0;\n                bool _5155 = !_5154;\n                bool _5161;\n                if (_5155)\n                {\n                    _5161 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5161 = _5154;\n                }\n                float _5162;\n                if (_5161)\n                {\n                    _5162 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5162 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5146, 80.0));\n                }\n                bool _5189;\n                if (_5155)\n                {\n                    _5189 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5189 = _5154;\n                }\n                float _5190;\n                if (_5189)\n                {\n                    _5190 = fa_mesh_fs_params[8].y * _5146;\n                }\n                else\n                {\n                    _5190 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5146, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5215 = _5151 <= 0.0;\n                bool _5222;\n                if (!_5215)\n                {\n                    _5222 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5222 = _5215;\n                }\n                float _5223;\n                if (_5222)\n                {\n                    _5223 = fa_mesh_fs_params[8].y * _5151;\n                }\n                else\n                {\n                    _5223 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5151, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5250;\n                if (abs(_5141) < 0.001000000047497451305389404296875)\n                {\n                    _5250 = _5162;\n                }\n                else\n                {\n                    _5250 = (_5223 - _5190) / _5141;\n                }\n                tau += (_5091 * max(_5250, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5347);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_441",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2098",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _830 = base_t;\n    _830.x = _227.x;\n    _830.y = _227.y;\n    _830.z = _227.z;\n    base_t = _830;\n    vec4 _243 = (_830 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _785 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _838 = _281;\n        _838.x = _286.x;\n        _838.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _838;\n        _785 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _841 = mrt;\n    _841.x = _315.x;\n    _841.y = _315.y;\n    _841.z = _315.z;\n    mrt = _841;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _790 = fa_mesh_fs_params[20].x;\n    float _791 = fa_mesh_fs_params[20].y;\n    float _794 = fa_mesh_fs_params[20].z;\n    float _793 = fa_mesh_fs_params[21].w;\n    float _796 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _790 *= _357.y;\n            _791 *= _357.z;\n            _793 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _794 *= mrt.x;\n            _796 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _785, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _790, _791, fa_mesh_fs_params[21].xyz, _793, _794, fa_mesh_fs_params[20].w, _796, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _680 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _680 = -_680;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _680, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _680, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _830 = base_t;\n    _830.x = _227.x;\n    _830.y = _227.y;\n    _830.z = _227.z;\n    base_t = _830;\n    vec4 _243 = (_830 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _785 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _838 = _281;\n        _838.x = _286.x;\n        _838.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _838;\n        _785 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _841 = mrt;\n    _841.x = _315.x;\n    _841.y = _315.y;\n    _841.z = _315.z;\n    mrt = _841;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _790 = fa_mesh_fs_params[20].x;\n    float _791 = fa_mesh_fs_params[20].y;\n    float _794 = fa_mesh_fs_params[20].z;\n    float _793 = fa_mesh_fs_params[21].w;\n    float _796 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _790 *= _357.y;\n            _791 *= _357.z;\n            _793 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _794 *= mrt.x;\n            _796 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _785, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _790, _791, fa_mesh_fs_params[21].xyz, _793, _794, fa_mesh_fs_params[20].w, _796, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _680 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _680 = -_680;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _680, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _680, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
