{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "738bdbaa5d236ca82c68b48e7af94b35c54ba5d6311eabf2bcbbc814ba3d221c",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1863[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _759 = fa_mesh_fs_params[19].x < 0.0;\n    bool _766;\n    if (!_759)\n    {\n        _766 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return ivec2(0);\n    }\n    vec4 _798 = vec4(world_pos, 1.0);\n    float _805 = dot(fa_mesh_fs_params[16], _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _827 = vec2(dot(fa_mesh_fs_params[14], _798), dot(fa_mesh_fs_params[15], _798)) / vec2(_805);\n    int _831 = int(fa_mesh_fs_params[18].x);\n    int _835 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _831 - 1);\n    vec4 _906 = fa_light_texel(param);\n    return ivec2(int(_906.x), int(_906.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2411 = fa_cluster_lookup(param);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _218;\n    if (i.front_facing)\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    vec3 _242 = normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    vec3 _270 = normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    vec3 _273;\n    if (i.front_facing)\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2697 = fa_tex_fix(param_2, param_3);\n    vec4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    vec4 _2711 = (_3619 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3543 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2743 = fa_tex_fix(param_6, param_7);\n        vec3 _2747 = (_2743 * 2.0) - vec3(1.0);\n        vec2 _2752 = _2747.xy * fa_mesh_fs_params[6].x;\n        vec3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2780 = fa_tex_fix(param_12, param_13);\n    vec4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    vec4 _2808 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = fa_mesh_fs_params[20].x;\n    float _3549 = fa_mesh_fs_params[20].y;\n    float _3552 = fa_mesh_fs_params[20].z;\n    float _3551 = fa_mesh_fs_params[21].w;\n    float _3554 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    return Surface(_2711.xyz, _2711.w, _3543, clamp(fa_mesh_fs_params[5].x * _2780.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2780.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2820.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2850), _3548, _3549, fa_mesh_fs_params[21].xyz, _3551, _3552, fa_mesh_fs_params[20].w, _3554, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10)\n    {\n        _382 = atan(_371, _367) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_382 - floor(_382)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _415 = fa_light_base(param);\n    bool _419 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _415;\n    vec4 _423 = fa_light_texel(param_1);\n    int param_2 = _415 + 1;\n    vec4 _428 = fa_light_texel(param_2);\n    float _431 = _428.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _443 = _419 && (_431 > 2.5);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5;\n    vec3 l;\n    if (_446)\n    {\n        l = normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            vec4 _460 = fa_light_texel(param_3);\n            if (_460.z > 0.5)\n            {\n                int param_4 = _415 + 4;\n                vec4 _470 = fa_light_texel(param_4);\n                int param_5 = _415 + 5;\n                vec4 _476 = fa_light_texel(param_5);\n                vec2 param_6 = _460.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / vec3(max(_510, 9.9999997473787516355514526367188e-05));\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _542 = reach / max(_423.w, 0.001000000047497451305389404296875);\n        float _548 = clamp(1.0 - (_542 * _542), 0.0, 1.0);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5;\n        if ((_431 > 1.5) && _556)\n        {\n            int param_9 = _415 + 2;\n            vec4 _564 = fa_light_texel(param_9);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            vec4 _580 = fa_light_texel(param_10);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5)\n            {\n                cos_inner = mix(_574, 1.0, 0.25);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            vec4 _605 = fa_light_texel(param_11);\n            int param_12 = _415 + 7;\n            vec4 _610 = fa_light_texel(param_12);\n            bool _613 = _605.z > 0.5;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                vec4 _627 = fa_light_texel(param_13);\n                vec3 _631 = normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                vec4 _636 = fa_light_texel(param_14);\n                int param_15 = _415 + 5;\n                vec4 _641 = fa_light_texel(param_15);\n                if (_613)\n                {\n                    vec3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5 / max(dot(_649, _631) * (sqrt(max(1.0 - (_656 * _656), 0.0)) / max(_656, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _605.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_649, _636.xyz) * _672), 0.5 - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_610.z > 0.5)\n                {\n                    vec2 param_18 = _610.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _631;\n                    vec3 param_21 = _636.xyz;\n                    vec3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5) && (_431 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _3381, atten, 1.0, dist, _741);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count();\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2);\n    return _2515;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1004 = fa_shadows[24].w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1042 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1047 = clamp(dot(n, l), 0.0, 1.0);\n    float _1053 = sqrt(1.0 - (_1047 * _1047));\n    float _1061 = min(_1053 / max(_1047, 0.20000000298023223876953125), 4.0);\n    float _1066;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1066 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1066 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1091 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1066 * _1053)), 1.0);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < fa_shadows[ci * 1 + 16].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0;\n    }\n    float _1143;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1143 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1143 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0 + (0.5 * _1061))) / _1042);\n    float _1171 = ((fa_shadows[ci * 1 + 20].x * min(_1061, 3.0)) * 0.5) / _1042;\n    int _1180 = int(fa_shadows[25].z + 0.5);\n    if (_1180 == 1)\n    {\n        vec2 param = _1091.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1191 = fa_shadow_depth(param, param_1);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = clamp(((fa_shadows[25].w * _1042) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            vec2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            vec2 param_5 = _1091.xy + (_1234 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1245 = fa_shadow_depth(param_5, param_6);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1162 - (sum / cnt), 0.0) * _1042) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        vec2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1091.xy + (_1308 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1319 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1349 = int(fa_shadows[25].x + 0.5);\n    if (_1349 < 1)\n    {\n        return 1.0;\n    }\n    float _1364 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1431;\n        if (_1431 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1456 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1475 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1456, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1486 = clamp((_1364 - (fa_shadow_split_at(param_7) - _1475)) / _1475, 0.0, 1.0);\n        if (_1486 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1507;\n                if (_1507 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1);\n    vec3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    return LightSample(_2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count();\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3);\n    return _2492;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1788 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1796 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return mix(mix(_1863[_1868], _1863[_1868 + 1], _1812), mix(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0;\n    float _3395 = 1.0;\n    float _3396 = 1.0;\n    float _3397 = 0.0;\n    float _3398 = 0.0;\n    float _3399 = 0.0;\n    float _3400 = 0.0;\n    float _3402 = 1.0;\n    bool _3403 = false;\n    vec3 _3404 = vec3(0.0);\n    float _3405 = 1.0;\n    float _3406 = 1.0;\n    float _3407 = 1.0;\n    float _3408 = 0.0;\n    float _3409 = 0.0;\n    vec3 _3410 = vec3(1.0, 0.0, 0.0);\n    vec3 _3411 = vec3(0.0, 0.0, 1.0);\n    float _3412 = 1.0;\n    float _3413 = 1.0;\n    float _1942 = clamp(s.specular, 0.0, 1.0);\n    float _1946 = clamp(s.ior, 1.0, 3.0);\n    bool _1951 = (_1942 != 1.0) || (_1946 != 1.5);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0) / (_1946 + 1.0);\n        f0 = mix(min(vec3(_1968 * _1968) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1942, s.albedo, vec3(metallic));\n        _3394 = mix(_1942, 1.0, metallic);\n        _3393 = true;\n    }\n    float _1996 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1996 > 0.0)\n    {\n        float _2004 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3402 = _2023;\n        _3395 = 1.0 - (_1996 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2023, 0.0, 1.0), 5.0))));\n        _3393 = true;\n    }\n    vec3 _2043 = max(s.sheen_color, vec3(0.0));\n    float _2052 = max(_2043.x, max(_2043.y, _2043.z));\n    if (_2052 > 0.0)\n    {\n        float _2060 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0 - min(_2052 * _2077, 1.0);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2096 != 0.0)\n    {\n        vec3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2125 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2125.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2125.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2125.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2129 = t;\n        vec3 _2130 = normalize(_2129);\n        t = _2130;\n        vec3 _2155 = normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = mix(_2165, 1.0, _2096 * _2096);\n        bool _2173 = _2096 > 0.0;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    return FaLayers(_3393, _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1720 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1723 = _1720.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1723 * _1723, exp2((-9.27999973297119140625) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625 * _1643;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1643)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1673, 0.0500000007450580596923828125 + _1673, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1643 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2206;\n        if (L.aniso >= 0.0)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2206, v), _2206), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2239 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2239.x) + (vec3(L.f90) * _2239.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2294 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1762 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1762.x) + vec3(_1762.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2333 = clamp(s.metallic, 0.0, 1.0);\n    float _2337 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2344 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2333));\n    vec3 f0 = _2344;\n    vec3 _2348 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2348;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    vec3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        vec3 param_8 = _2348;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2348;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1);\n        float _2543 = dot(_2535.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5)\n        {\n            _2580 = 1.0;\n        }\n        else\n        {\n            _2580 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1531 = int(fa_shadows[25].x + 0.5);\n    float _1541 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    vec3 _2971 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n    Surface _2979 = fa_standard_surface(param_1);\n    vec3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    vec3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    vec3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    vec3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    vec3 _3313 = _2979.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3298;\n    }\n    else\n    {\n        vec3 _3000 = _3300;\n        vec3 _3001 = normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n        Surface param_5 = Surface(_3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313);\n        vec3 _3012 = lighting(param_4, param_5);\n        result = _3012;\n    }\n    vec3 _3016 = result;\n    vec3 _3017 = _3016 + _3304;\n    result = _3017;\n    vec3 param_6 = _3017;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3026 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        vec3 _3042 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3048 = dot(_3042, fa_mesh_fs_params[9].xyz);\n        bool _3052 = fa_mesh_fs_params[9].w > 0.5;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - fa_mesh_fs_params[8].x;\n        if (_3065 > 0.0)\n        {\n            float _3074 = fa_mesh_fs_params[7].w * _3065;\n            float tau = _3074 * _3074;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3048);\n                }\n                else\n                {\n                    _3090 = fa_mesh_fs_params[0].y;\n                }\n                float _3111 = mix(_3090, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3053, 0.0, 1.0));\n                float _3115 = fa_world_pos.y - _3111;\n                float _3120 = _3111 - fa_mesh_fs_params[8].z;\n                float _3125 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3128 = _3120 <= 0.0;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3136 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3120, 80.0));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = fa_mesh_fs_params[8].y * _3120;\n                }\n                else\n                {\n                    _3164 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3120, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3189 = _3125 <= 0.0;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = fa_mesh_fs_params[8].y * _3125;\n                }\n                else\n                {\n                    _3197 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3125, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * max(_3224, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3299);\n}\n\n",
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
            "inst_name": "_286",
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
            "inst_name": "_990",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1863[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _759 = fa_mesh_fs_params[19].x < 0.0;\n    bool _766;\n    if (!_759)\n    {\n        _766 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    bool _774;\n    if (!_766)\n    {\n        _774 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _774 = _766;\n    }\n    bool _781;\n    if (!_774)\n    {\n        _781 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _781 = _774;\n    }\n    bool _788;\n    if (!_781)\n    {\n        _788 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _788 = _781;\n    }\n    if (_788)\n    {\n        return ivec2(0);\n    }\n    vec4 _798 = vec4(world_pos, 1.0);\n    float _805 = dot(fa_mesh_fs_params[16], _798);\n    if (!(_805 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _827 = vec2(dot(fa_mesh_fs_params[14], _798), dot(fa_mesh_fs_params[15], _798)) / vec2(_805);\n    int _831 = int(fa_mesh_fs_params[18].x);\n    int _835 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _835) + clamp(int(floor(((_827.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _835 - 1)) * _831)) + clamp(int(floor(((_827.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _831 - 1);\n    vec4 _906 = fa_light_texel(param);\n    return ivec2(int(_906.x), int(_906.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2411 = fa_cluster_lookup(param);\n    fa_cl_slot = _2411.x;\n    fa_cl_local = _2411.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2658 = fa_linear_to_srgb(param);\n        c = _2658;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2666 = fa_srgb_to_linear(param_1);\n            c = _2666;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _218;\n    if (i.front_facing)\n    {\n        _218 = i.world_normal;\n    }\n    else\n    {\n        _218 = -i.world_normal;\n    }\n    vec3 _242 = normalize(i.world_tangent.xyz - (_218 * dot(_218, i.world_tangent.xyz)));\n    vec3 _270 = normalize(((_242 * m.x) + ((cross(_218, _242) * i.world_tangent.w) * m.y)) + (_218 * m.z));\n    vec3 _273;\n    if (i.front_facing)\n    {\n        _273 = _270;\n    }\n    else\n    {\n        _273 = -_270;\n    }\n    return _273;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2697 = fa_tex_fix(param_2, param_3);\n    vec4 _3619 = base_t;\n    _3619.x = _2697.x;\n    _3619.y = _2697.y;\n    _3619.z = _2697.z;\n    base_t = _3619;\n    vec4 _2711 = (_3619 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3543 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2743 = fa_tex_fix(param_6, param_7);\n        vec3 _2747 = (_2743 * 2.0) - vec3(1.0);\n        vec2 _2752 = _2747.xy * fa_mesh_fs_params[6].x;\n        vec3 _3627 = _2747;\n        _3627.x = _2752.x;\n        _3627.y = _2752.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3627;\n        _3543 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2780 = fa_tex_fix(param_12, param_13);\n    vec4 _3630 = mrt;\n    _3630.x = _2780.x;\n    _3630.y = _2780.y;\n    _3630.z = _2780.z;\n    mrt = _3630;\n    vec4 _2808 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2808.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2820 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2850 = fa_tex_fix(param_20, param_21);\n    float _3548 = fa_mesh_fs_params[20].x;\n    float _3549 = fa_mesh_fs_params[20].y;\n    float _3552 = fa_mesh_fs_params[20].z;\n    float _3551 = fa_mesh_fs_params[21].w;\n    float _3554 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3548 *= _2820.y;\n            _3549 *= _2820.z;\n            _3551 *= _2808.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3552 *= mrt.x;\n            _3554 *= mrt.w;\n        }\n    }\n    return Surface(_2711.xyz, _2711.w, _3543, clamp(fa_mesh_fs_params[5].x * _2780.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2780.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2820.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2850), _3548, _3549, fa_mesh_fs_params[21].xyz, _3551, _3552, fa_mesh_fs_params[20].w, _3554, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _367 = dot(d, right);\n    float _371 = dot(d, up);\n    float _382;\n    if (((_367 * _367) + (_371 * _371)) > 1.0000000133514319600180897396058e-10)\n    {\n        _382 = atan(_371, _367) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_382 - floor(_382)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _415 = fa_light_base(param);\n    bool _419 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _415;\n    vec4 _423 = fa_light_texel(param_1);\n    int param_2 = _415 + 1;\n    vec4 _428 = fa_light_texel(param_2);\n    float _431 = _428.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _443 = _419 && (_431 > 2.5);\n    fa_light_is_area = _443;\n    bool _446 = _431 < 0.5;\n    vec3 l;\n    if (_446)\n    {\n        l = normalize(_423.xyz);\n        if (_419)\n        {\n            int param_3 = _415 + 6;\n            vec4 _460 = fa_light_texel(param_3);\n            if (_460.z > 0.5)\n            {\n                int param_4 = _415 + 4;\n                vec4 _470 = fa_light_texel(param_4);\n                int param_5 = _415 + 5;\n                vec4 _476 = fa_light_texel(param_5);\n                vec2 param_6 = _460.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _470.xyz) * _470.w, (-dot(world_pos, _476.xyz)) * _476.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _508 = _423.xyz - world_pos;\n        float _510 = length(_508);\n        dist = _510;\n        l = _508 / vec3(max(_510, 9.9999997473787516355514526367188e-05));\n        float reach = _510;\n        if (_443)\n        {\n            int param_8 = _415 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _542 = reach / max(_423.w, 0.001000000047497451305389404296875);\n        float _548 = clamp(1.0 - (_542 * _542), 0.0, 1.0);\n        atten = _548 * _548;\n        bool _556 = _431 < 2.5;\n        if ((_431 > 1.5) && _556)\n        {\n            int param_9 = _415 + 2;\n            vec4 _564 = fa_light_texel(param_9);\n            float _574 = _564.w;\n            int param_10 = _415 + 3;\n            vec4 _580 = fa_light_texel(param_10);\n            float _581 = _580.x;\n            float cos_inner = _581;\n            if (_581 > 1.5)\n            {\n                cos_inner = mix(_574, 1.0, 0.25);\n            }\n            atten *= smoothstep(_574, cos_inner, dot(-l, normalize(_564.xyz)));\n        }\n        if (_419 && _556)\n        {\n            int param_11 = _415 + 6;\n            vec4 _605 = fa_light_texel(param_11);\n            int param_12 = _415 + 7;\n            vec4 _610 = fa_light_texel(param_12);\n            bool _613 = _605.z > 0.5;\n            bool _620;\n            if (!_613)\n            {\n                _620 = _610.z > 0.5;\n            }\n            else\n            {\n                _620 = _613;\n            }\n            if (_620)\n            {\n                int param_13 = _415 + 2;\n                vec4 _627 = fa_light_texel(param_13);\n                vec3 _631 = normalize(_627.xyz);\n                int param_14 = _415 + 4;\n                vec4 _636 = fa_light_texel(param_14);\n                int param_15 = _415 + 5;\n                vec4 _641 = fa_light_texel(param_15);\n                if (_613)\n                {\n                    vec3 _649 = -_508;\n                    float _656 = _627.w;\n                    float _672 = 0.5 / max(dot(_649, _631) * (sqrt(max(1.0 - (_656 * _656), 0.0)) / max(_656, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _605.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_649, _636.xyz) * _672), 0.5 - (dot(_649, _641.xyz) * _672));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_610.z > 0.5)\n                {\n                    vec2 param_18 = _610.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _631;\n                    vec3 param_21 = _636.xyz;\n                    vec3 param_22 = _641.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _3381 = _428.xyz * atten;\n    if (_419)\n    {\n        _3381 *= fa_light_tint;\n    }\n    int _741;\n    if (_446)\n    {\n        _741 = 0;\n    }\n    else\n    {\n        _741 = ((_431 > 1.5) && (_431 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _3381, atten, 1.0, dist, _741);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2496 = n < 0;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = n >= fa_light_count();\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    LightSample _2515 = fa_light_sample(param_1, param_2);\n    return _2515;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _980;\n    if (i == 0)\n    {\n        _980 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _996;\n        if (i == 1)\n        {\n            _996 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1004;\n            if (i == 2)\n            {\n                _1004 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1004 = fa_shadows[24].w;\n            }\n            _996 = _1004;\n        }\n        _980 = _996;\n    }\n    return _980;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _968 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_968), sin(_968)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1042 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1047 = clamp(dot(n, l), 0.0, 1.0);\n    float _1053 = sqrt(1.0 - (_1047 * _1047));\n    float _1061 = min(_1053 / max(_1047, 0.20000000298023223876953125), 4.0);\n    float _1066;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1066 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1066 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1091 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1066 * _1053)), 1.0);\n    float _1098 = _1091.x;\n    bool _1101 = _1098 < fa_shadows[ci * 1 + 16].x;\n    bool _1110;\n    if (!_1101)\n    {\n        _1110 = _1098 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1110 = _1101;\n    }\n    bool _1119;\n    if (!_1110)\n    {\n        _1119 = _1091.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1119 = _1110;\n    }\n    bool _1128;\n    if (!_1119)\n    {\n        _1128 = _1091.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1128 = _1119;\n    }\n    bool _1135;\n    if (!_1128)\n    {\n        _1135 = _1091.z > 1.0;\n    }\n    else\n    {\n        _1135 = _1128;\n    }\n    if (_1135)\n    {\n        return -1.0;\n    }\n    float _1143;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1143 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1143 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1162 = _1091.z - ((_1143 * (1.0 + (0.5 * _1061))) / _1042);\n    float _1171 = ((fa_shadows[ci * 1 + 20].x * min(_1061, 3.0)) * 0.5) / _1042;\n    int _1180 = int(fa_shadows[25].z + 0.5);\n    if (_1180 == 1)\n    {\n        vec2 param = _1091.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1191 = fa_shadow_depth(param, param_1);\n        return float(_1162 <= _1191);\n    }\n    float _1198 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1201 = _1180 == 2;\n    if (_1201)\n    {\n        float _1215 = clamp(((fa_shadows[25].w * _1042) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1198;\n            vec2 _1234 = fa_shadow_vogel(param_2, param_3, param_4) * _1215;\n            vec2 param_5 = _1091.xy + (_1234 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1245 = fa_shadow_depth(param_5, param_6);\n            if (_1245 < (_1162 - (length(_1234) * _1171)))\n            {\n                sum += _1245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1162 - (sum / cnt), 0.0) * _1042) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1289 = _1201 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1289; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1289;\n        float param_9 = _1198;\n        vec2 _1308 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1091.xy + (_1308 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1319 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1162 - (length(_1308) * _1171)) <= _1319);\n    }\n    return lit / float(_1289);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1349 = int(fa_shadows[25].x + 0.5);\n    if (_1349 < 1)\n    {\n        return 1.0;\n    }\n    float _1364 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1349 - 1;\n    if (_1364 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1376 = _1349 > 1;\n    bool _1383;\n    if (_1376)\n    {\n        _1383 = _1364 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    if (_1383)\n    {\n        ci = 1;\n    }\n    bool _1387 = _1349 > 2;\n    bool _1394;\n    if (_1387)\n    {\n        _1394 = _1364 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1394 = _1387;\n    }\n    if (_1394)\n    {\n        ci = 2;\n    }\n    bool _1398 = _1349 > 3;\n    bool _1405;\n    if (_1398)\n    {\n        _1405 = _1364 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1405 = _1398;\n    }\n    if (_1405)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1349)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1431 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1431;\n        if (_1431 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1456;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1456 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1456 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1475 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1456, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1486 = clamp((_1364 - (fa_shadow_split_at(param_7) - _1475)) / _1475, 0.0, 1.0);\n        if (_1486 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1349)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1507 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1507;\n                if (_1507 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1486);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2439 = fa_light_sample(param, param_1);\n    vec3 _3514 = _2439.color;\n    float _3516 = _2439.shadow;\n    if ((_2439.type == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2439.direction;\n        float _2453 = fa_shadow_factor(param_2, param_3);\n        _3516 = _2453;\n        _3514 *= _2453;\n    }\n    return LightSample(_2439.direction, _3514, _2439.attenuation, _3516, _2439._distance, _2439.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2470 = n < 0;\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = n >= fa_light_count();\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _2492 = fa_light_shadowed(param_1, param_2, param_3);\n    return _2492;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1788 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1796 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1799 = int(_1788);\n    int _1802 = int(_1796);\n    float _1812 = _1796 - float(_1802);\n    int _1868 = (_1799 * 9) + _1802;\n    int _1888 = ((_1799 + 1) * 9) + _1802;\n    return mix(mix(_1863[_1868], _1863[_1868 + 1], _1812), mix(_1863[_1888], _1863[_1888 + 1], _1812), _1788 - float(_1799));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3393 = false;\n    float _3394 = 1.0;\n    float _3395 = 1.0;\n    float _3396 = 1.0;\n    float _3397 = 0.0;\n    float _3398 = 0.0;\n    float _3399 = 0.0;\n    float _3400 = 0.0;\n    float _3402 = 1.0;\n    bool _3403 = false;\n    vec3 _3404 = vec3(0.0);\n    float _3405 = 1.0;\n    float _3406 = 1.0;\n    float _3407 = 1.0;\n    float _3408 = 0.0;\n    float _3409 = 0.0;\n    vec3 _3410 = vec3(1.0, 0.0, 0.0);\n    vec3 _3411 = vec3(0.0, 0.0, 1.0);\n    float _3412 = 1.0;\n    float _3413 = 1.0;\n    float _1942 = clamp(s.specular, 0.0, 1.0);\n    float _1946 = clamp(s.ior, 1.0, 3.0);\n    bool _1951 = (_1942 != 1.0) || (_1946 != 1.5);\n    bool _1960;\n    if (!_1951)\n    {\n        _1960 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1960 = _1951;\n    }\n    if (_1960)\n    {\n        float _1968 = (_1946 - 1.0) / (_1946 + 1.0);\n        f0 = mix(min(vec3(_1968 * _1968) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1942, s.albedo, vec3(metallic));\n        _3394 = mix(_1942, 1.0, metallic);\n        _3393 = true;\n    }\n    float _1996 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1996 > 0.0)\n    {\n        float _2004 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3397 = _1996;\n        _3398 = _2004;\n        float _2011 = _2004 * _2004;\n        _3399 = _2011;\n        _3400 = _2011 * _2011;\n        float _2023 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3402 = _2023;\n        _3395 = 1.0 - (_1996 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2023, 0.0, 1.0), 5.0))));\n        _3393 = true;\n    }\n    vec3 _2043 = max(s.sheen_color, vec3(0.0));\n    float _2052 = max(_2043.x, max(_2043.y, _2043.z));\n    if (_2052 > 0.0)\n    {\n        float _2060 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3403 = true;\n        _3404 = _2043;\n        _3405 = _2060;\n        _3406 = _2060 * _2060;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2060;\n        float _2077 = fa_sheen_albedo(param, param_1);\n        _3408 = _2077;\n        _3407 = 1.0 - min(_2052 * _2077, 1.0);\n        _3393 = true;\n    }\n    _3396 = _3395 * _3407;\n    float _2096 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2096 != 0.0)\n    {\n        vec3 _2111 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2111;\n        if (dot(_2111, _2111) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2125 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2125.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2125.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2125.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2129 = t;\n        vec3 _2130 = normalize(_2129);\n        t = _2130;\n        vec3 _2155 = normalize((_2130 * cos(s.anisotropy_rotation)) + ((cross(n, _2130) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3410 = _2155;\n        _3411 = cross(n, _2155);\n        float _2165 = roughness * roughness;\n        float _2171 = mix(_2165, 1.0, _2096 * _2096);\n        bool _2173 = _2096 > 0.0;\n        _3412 = _2173 ? _2171 : _2165;\n        _3413 = _2173 ? _2165 : _2171;\n        _3409 = _2096;\n        _3393 = true;\n    }\n    return FaLayers(_3393, _3394, _3395, _3396, _3397, _3398, _3399, _3400, i.world_normal, _3402, _3403, _3404, _3405, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1720 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1723 = _1720.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1723 * _1723, exp2((-9.27999973297119140625) * ndv)) * _1723) + _1720.y)) + _1720.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1643 = rough * rough;\n    float _1673 = 0.60000002384185791015625 * _1643;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1643)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1673, 0.0500000007450580596923828125 + _1673, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1643 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2206;\n        if (L.aniso >= 0.0)\n        {\n            _2206 = L.b;\n        }\n        else\n        {\n            _2206 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2206, v), _2206), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2239 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2239.x) + (vec3(L.f90) * _2239.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2294 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2294.x) + _2294.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1762 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1762.x) + vec3(_1762.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2333 = clamp(s.metallic, 0.0, 1.0);\n    float _2337 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2344 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2333));\n    vec3 f0 = _2344;\n    vec3 _2348 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2348;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2333;\n    float param_5 = _2337;\n    vec3 param_6 = _2344;\n    FaLayers _2365 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2365.on)\n    {\n        FaLayers param_7 = _2365;\n        vec3 param_8 = _2348;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2337;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2348;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2337;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _2535 = fa_light_unshadowed(param, param_1);\n        float _2543 = dot(_2535.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2543 > bestPower)\n        {\n            bestPower = _2543;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2572 = fa_light(param_2, param_3);\n        float _2580;\n        if (dot(s.normal, _2572.direction) > 0.5)\n        {\n            _2580 = 1.0;\n        }\n        else\n        {\n            _2580 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2572.color) * _2580);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1531 = int(fa_shadows[25].x + 0.5);\n    float _1541 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1546 = _1531 > 0;\n    bool _1555;\n    if (_1546)\n    {\n        int param = _1531 - 1;\n        _1555 = _1541 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1555 = _1546;\n    }\n    if (_1555)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1562 = _1531 > 1;\n        bool _1569;\n        if (_1562)\n        {\n            _1569 = _1541 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1569 = _1562;\n        }\n        if (_1569)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1575 = _1531 > 2;\n        bool _1582;\n        if (_1575)\n        {\n            _1582 = _1541 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1582 = _1575;\n        }\n        if (_1582)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1588 = _1531 > 3;\n        bool _1595;\n        if (_1588)\n        {\n            _1595 = _1541 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1595 = _1588;\n        }\n        if (_1595)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3267 = -_3267;\n    }\n    vec3 _2971 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n    Surface _2979 = fa_standard_surface(param_1);\n    vec3 _3298 = _2979.albedo;\n    float _3299 = _2979.alpha;\n    vec3 _3300 = _2979.normal;\n    float _3301 = _2979.metallic;\n    float _3302 = _2979.roughness;\n    float _3303 = _2979.occlusion;\n    vec3 _3304 = _2979.emission;\n    float _3305 = _2979.clearcoat;\n    float _3306 = _2979.clearcoat_roughness;\n    vec3 _3307 = _2979.sheen_color;\n    float _3308 = _2979.sheen_roughness;\n    float _3309 = _2979.anisotropy;\n    float _3310 = _2979.anisotropy_rotation;\n    float _3311 = _2979.specular;\n    float _3312 = _2979.ior;\n    vec3 _3313 = _2979.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n    Surface param_3 = _2979;\n    surface(param_2, param_3);\n    _3298 = param_3.albedo;\n    _3299 = param_3.alpha;\n    _3300 = param_3.normal;\n    _3301 = param_3.metallic;\n    _3302 = param_3.roughness;\n    _3303 = param_3.occlusion;\n    _3304 = param_3.emission;\n    _3305 = param_3.clearcoat;\n    _3306 = param_3.clearcoat_roughness;\n    _3307 = param_3.sheen_color;\n    _3308 = param_3.sheen_roughness;\n    _3309 = param_3.anisotropy;\n    _3310 = param_3.anisotropy_rotation;\n    _3311 = param_3.specular;\n    _3312 = param_3.ior;\n    _3313 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3298;\n    }\n    else\n    {\n        vec3 _3000 = _3300;\n        vec3 _3001 = normalize(_3000);\n        _3300 = _3001;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3267, fa_world_tangent, fa_uv, fa_vertex_color, _2971, gl_FrontFacing);\n        Surface param_5 = Surface(_3298, _3299, _3001, _3301, _3302, _3303, _3304, _3305, _3306, _3307, _3308, _3309, _3310, _3311, _3312, _3313);\n        vec3 _3012 = lighting(param_4, param_5);\n        result = _3012;\n    }\n    vec3 _3016 = result;\n    vec3 _3017 = _3016 + _3304;\n    result = _3017;\n    vec3 param_6 = _3017;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3026 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3033;\n    if (!_3026)\n    {\n        _3033 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3033 = _3026;\n    }\n    if (_3033)\n    {\n        vec3 _3042 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3048 = dot(_3042, fa_mesh_fs_params[9].xyz);\n        bool _3052 = fa_mesh_fs_params[9].w > 0.5;\n        float _3053;\n        if (_3052)\n        {\n            _3053 = _3048;\n        }\n        else\n        {\n            _3053 = length(_3042);\n        }\n        float _3065 = _3053 - fa_mesh_fs_params[8].x;\n        if (_3065 > 0.0)\n        {\n            float _3074 = fa_mesh_fs_params[7].w * _3065;\n            float tau = _3074 * _3074;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3090;\n                if (_3052)\n                {\n                    _3090 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3048);\n                }\n                else\n                {\n                    _3090 = fa_mesh_fs_params[0].y;\n                }\n                float _3111 = mix(_3090, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3053, 0.0, 1.0));\n                float _3115 = fa_world_pos.y - _3111;\n                float _3120 = _3111 - fa_mesh_fs_params[8].z;\n                float _3125 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3128 = _3120 <= 0.0;\n                bool _3129 = !_3128;\n                bool _3135;\n                if (_3129)\n                {\n                    _3135 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3135 = _3128;\n                }\n                float _3136;\n                if (_3135)\n                {\n                    _3136 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3136 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3120, 80.0));\n                }\n                bool _3163;\n                if (_3129)\n                {\n                    _3163 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3163 = _3128;\n                }\n                float _3164;\n                if (_3163)\n                {\n                    _3164 = fa_mesh_fs_params[8].y * _3120;\n                }\n                else\n                {\n                    _3164 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3120, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3189 = _3125 <= 0.0;\n                bool _3196;\n                if (!_3189)\n                {\n                    _3196 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3196 = _3189;\n                }\n                float _3197;\n                if (_3196)\n                {\n                    _3197 = fa_mesh_fs_params[8].y * _3125;\n                }\n                else\n                {\n                    _3197 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3125, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3224;\n                if (abs(_3115) < 0.001000000047497451305389404296875)\n                {\n                    _3224 = _3136;\n                }\n                else\n                {\n                    _3224 = (_3197 - _3164) / _3115;\n                }\n                tau += (_3065 * max(_3224, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3299);\n}\n\n",
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
            "inst_name": "_286",
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
            "inst_name": "_990",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2586",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    vec4 _241 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _750, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
