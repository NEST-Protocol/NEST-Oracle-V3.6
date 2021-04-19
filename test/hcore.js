
/**
 * js基础工具库
 * */
function $hcj() {
}

(function ($hcj) {

	/**
	 * 字符串工具类
	 * @param {any} str
	 * @param {any} start
	 * @param {any} length
	 */
	var SStr = function (str, start, length) {
		this.str = str = str || '';
		this.start = start == undefined ? 0 : start;
		this.length = length == undefined ? str.length : length;
	};

	(function (SStr) {
		/**
		 * 判断字符是否是空白
		 * @param {any} ch
		 */
		SStr.IsWhiteSpace = function (ch) {
			return ch == ' ' || ch == '\t';
		};

		/**
		 * 判断字符是否是数字符号
		 * @param {any} ch
		 */
		SStr.IsDigit = function (ch) {
			return '0123456789'.indexOf(ch) != -1;
		};

		/**
		 * 获取指向结尾字符后的索引号
		 * */
		SStr.prototype.end = function () {
			return this.start + this.length;
		};

		/**
		 * 获取字符串
		 * */
		SStr.prototype.val = function () {
			return this.str.substr(this.start, this.length);
		};

		/**
		 * 去空格
		 * */
		SStr.prototype.trim = function () {
			var left = this.start;
			var right = this.start + this.length;
			while (left < right) {
				if (SStr.IsWhiteSpace(this.str.charAt(left))) {
					++left;
				} else {
					break;
				}
			}
			while (left < right) {
				if (SStr.IsWhiteSpace(this.str.charAt(right - 1))) {
					--right;
				} else {
					break;
				}
			}

			return new SStr(this.str, left, right - left);
		};

		/**
		 * 获取指定位置的字符
		 * @param {any} index
		 */
		SStr.prototype.charAt = function (index) {
			return this.str[this.start + index];
		};

		/**
		 * 查找字符
		 * @param {any} c
		 */
		SStr.prototype.indexOf = function (c) {
			var index = this.str.indexOf(c, this.start);
			if (index > -1) {
				index -= this.start;
				if (index < this.length) {
					return index;
				}
			}

			return -1;
		};

		/**
		 * 创建子字符串（起始索引和字符串长度）
		 * @param {any} start
		 * @param {any} length
		 */
		SStr.prototype.substr = function (start, length) {
			return new SStr(this.str, this.start + start, length == undefined ? (this.length - this.start - start) : length);
		};

		/**
		 * 创建子字符串（起始索引和结束后索引）
		 * @param {any} start
		 * @param {any} end
		 */
		SStr.prototype.substring = function (start, end) {
			return this.substr(start, (end == undefined ? this.length : end) - start);
		};

		/**
		 * 获取字符串
		 * */
		SStr.prototype.toString = function () {
			return this.val();
		}
	})(SStr);

	/**
	 * 创建字符串
	 * @param {any} str
	 * @param {any} start
	 * @param {any} length
	 */
	$hcj.newSStr = function (str, start, length) {
		return new SStr(str, start, length);
	};

	/**
	 * 创建对象上下文
	 * @param {any} obj
	 */
	var ObjCtx = function (obj) {
		this.obj = obj;
	};

	(function (ObjCtx) {
		/**
		 * 获取属性
		 * @param {any} key
		 */
		ObjCtx.prototype.__get__ = function (key) {
			var obj = this.obj;
			if (key == 'this') {
				return obj;
			}
			if (obj == null || obj == undefined) {
				return null;
			}
			if ($hcj.isFunction(obj)) {
				return obj(key);
			}
			// 当前args参数并没有起作用
			// by chenf 2019-03-10
			key = $hcj.trim(key);

			if (obj.__get__) {
				return obj.__get__(key);
			}

			return obj[key];
		};
	})(ObjCtx);

	/**
	 * 创建对象上下文
	 * @param {any} ctx
	 */
	$hcj.newObjCtx = function (ctx) {
		return new ObjCtx(ctx);
	};

	/**
	 * 创建可计算上下文
	 * @param {any} ctx
	 */
	var EvalCtx = function (ctx) {
		this.ctx = ctx;
	};

	(function (EvalCtx) {
		/**
		 * 获取属性
		 * @param {any} key
		 */
		EvalCtx.prototype.__get__ = function (key) {
			if (key == 'this') {
				return this.ctx;
			}
			return $hcj.eval(key, this.ctx);
		};
	})(EvalCtx);

	/**
	 * 创建可计算上下文
	 * @param {any} ctx
	 */
	$hcj.newEvalCtx = function (ctx) {
		return new EvalCtx(ctx);
	};

	// 标准日期时间格式
	$hcj.stdTimeFmt = 'yyyy-MM-ddTHH:mm:ss.msK';

	// 复制属性
	$hcj.copyProperties = function (dest, src) {
		var prop_list = Object.getOwnPropertyNames(src);
		for (var i = 0; i < prop_list.length; ++i) {
			var prop_name = prop_list[i];
			dest[prop_name] = src[prop_name];
		}
	};

	// 用于获取格式字符下标的函数
	var getPartIndex = function (fmt, part1, part2) {
		var index = fmt.indexOf(part1);
		if (index == -1 && null != part2) {
			index = fmt.indexOf(part2);
		}
		if (index == -1)
			return 999;
		else
			return index;
	};

	// 用于从匹配中获取值的函数
	var getMatchValue = function (mc, i, i2) {
		if (mc.length > i) {
			return parseInt(mc[i], 10);
		}
		if (i2 && mc.length > i2) {
			return getMatchValue(mc, i2);
		}

		return 0;
	};

	/**
	* 将一个字符串转换为日期
	* @param {Object} str: 必须, string, 目标字符串
	* @param {Object} fmt: 可选, string, 格式字符串, 默认为 'yyyy-MM-dd', 不要包含正则表达式定义的特殊字符
	*/
	$hcj.parseDate = function (str, fmt) {
		// TODO: 解决时区问题。添加时区设置
		if (!str) return null;
		if (null == fmt)
			fmt = 'yyyy-MM-dd';
		// 第个日期部分对应的下标和匹配中的组编号的实体数组
		var gis = [{
			i: getPartIndex(fmt, 'yyyy', '%y'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'MM', '%M'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'dd', '%d'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'HH', '%H'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'mm', '%m'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'ss', '%s'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'ms'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'K'),
			g: 1
		}, {
			i: getPartIndex(fmt, 'fff'),
			g: 1
		}];
		// 根据日期部分下标排列组
		for (var i = 0; i != gis.length; ++i) {
			for (var j = 0; j != i; ++j) {
				if (gis[i].i > gis[j].i)
					++gis[i].g; //gis[i].g = gis[i].g + 1;
				else
					++gis[j].g; //gis[j].g = gis[j].g + 1;
			}
		}
		// 替换为正则表达式
		//fmt = fmt.replace('(','[(]').replace(')','[)]').replace('yyyy', '(\\d{1,4})').replace('MM', '(\\d{1,2})').replace('dd', '(\\d{1,2})').replace('%y', '(\\d{1,4})').replace('%M', '(\\d{1,2})').replace('%d', '(\\d{1,2})').replace('HH', '(\\d{1,2})').replace('mm', '(\\d{1,2})').replace('ss', '(\\d{1,2})').replace('%H', '(\\d{1,2})').replace('%m', '(\\d{1,2})').replace('%s', '(\\d{1,2})');
		fmt = fmt.replace(/[(]|[)]|[\\]|[\/]|[|]/g, function (mc) {
			switch (mc) {
				case '\\':
					return '[\\\\]';
				default:
					return '[' + mc + ']';
			}
		});
		fmt = fmt.replace(/(yyyy)|(MM)|(dd)|(HH)|(mm)|(fff)|(ss)|(ms)|(%y)|(%M)|(%d)|(%H)|(%m)|(%s)|(K)/g, function (mc) {
			if ('yyyy' == mc)
				return '(\\d{1,4})';
			else if ('ms' == mc || 'fff' == mc)
				return '(\\d{1,3})';
			else if (mc == 'K')
				return '(\\+\\d\\d[:]\\d\\d)';
			else
				return '(\\d{1,2})';
		});
		var mc = str.match(fmt);
		if (mc == null) {
			return null;
		}
		// 从匹配中分析日期
		return new Date(getMatchValue(mc, gis[0].g), getMatchValue(mc, gis[1].g) - 1, getMatchValue(mc, gis[2].g), getMatchValue(mc, gis[3].g), getMatchValue(mc, gis[4].g), getMatchValue(mc, gis[5].g), getMatchValue(mc, gis[6].g, gis[8].g));
	};

	/**
	* 将一个日期格式化为字符串
	* @param {Object} oDate: 日期对象
	* @param {Object} fmt: 可选, string, 格式字符串, 默认为 'yyyy-MM-dd HH:mm:ss'
	*/
	$hcj.formatDate = function (oDate, fmt) {
		if (null == fmt)
			fmt = 'yyyy-MM-dd HH:mm:ss';
		var fs = this.fillStr;
		return fmt.replace(/(yyyy)|(MM)|(dd)|(HH)|(mm)|(ss)|(fff)|(ms)|(%y)|(%M)|(%d)|(%H)|(%m)|(%s)|(K)/g, function (mc) {
			switch (mc) {
				case 'yyyy':
					return fs(oDate.getFullYear(), 4);
				case 'MM':
					return fs(oDate.getMonth() + 1, 2);
				case 'dd':
					return fs(oDate.getDate(), 2);
				case 'HH':
					return fs(oDate.getHours(), 2);
				case 'mm':
					return fs(oDate.getMinutes(), 2);
				case 'ss':
					return fs(oDate.getSeconds(), 2);
				case 'ms':
				case 'fff':
					return fs(oDate.getMilliseconds(), 3);
				case '%y':
					return oDate.getFullYear();
				case '%M':
					return oDate.getMonth() + 1;
				case '%d':
					return oDate.getDate();
				case '%H':
					return oDate.getHours();
				case '%m':
					return oDate.getMinutes();
				case '%s':
					return oDate.getSeconds();
				case 'K':
					var mins = oDate.getTimezoneOffset();
					if (mins < 0) {
						mins = -mins;
						return $hcj.format('+%02d:%02d', mins / 60, mins % 60);
					}
					return $hcj.format('-%02d:%02d', mins / 60, mins % 60);
			}
		});
	};

	/**
	* 以 spbs 指定的字符 '画刷' 填充字符串
	* @param {Object} str: 目标字符串
	* @param {Object} len: 要填充的长度, 如果 len <= str.length, 则不操作
	* @param {Object} spbs: '画刷', 默认为 '0000000000'(十个零)
	* @param {Object} align: 对齐方式 (L: 左对齐, R: 右对齐), 默认为右对齐
	*/
	$hcj.fillStr = function (str, len, spbs, align) {
		var tmp = str ? str.toString() : '';
		var dl;
		var ss;
		if (null == spbs)
			spbs = '0000000000';
		while ((dl = len - tmp.length) > 0) {
			ss = spbs.substr(0, dl);
			if ('L' == align) {
				tmp += ss;
			}
			else {
				tmp = ss + tmp;
			}
		}
		return tmp;
	};

	/**
	* 格式化字符串
	* 格式化说明符为 %, 如果要输出 %, 请使用 %%
	* 支持 d, s, x, f, o 格式化
	* @param {Object} fmt: 格式化说明字符串
	* @param {Object} args: 参数列表, 长度可变
	*/
	$hcj.format = function (fmt, args) {
		if (0 == arguments.length)
			return null;
		//var fmt = arguments[0];
		// 用于保存结果
		var res = '';
		// i: 遍历字符串的下标, pi: 当前要保存字符串的开始位置, ai: 参数下标, ni: 获取对齐长度时的数字字符串开始下标
		var i = 0, pi = 0, ai = 1, ni = 0;
		// 当前处理状态: 0 正常, 1, 确认是否有 -, 2, 确认是否有 0, 3 找数据宽度, 4, 找格式类型
		var state = 0;
		// 遍历字符串用的字符
		var cc;
		// 将参数转换为字符时的临时临时变量
		var as;
		// 保存参数值的临时变量
		var arg;
		// 格式化信息 { align: 'R', spcc: ' ', len: 0, dpc: 0, f: 'd' };
		var fi = {};
		// 数字常量
		var ncs = '0123456789';
		// 对齐时用于填补字符串的'画刷'
		var spbs = '          ';
		while (i < fmt.length) {
			cc = fmt.charAt(i);
			switch (state) {
				// 0 正常                                             
				case 0:
					if ('%' == cc) {
						if (i > pi) {
							res += fmt.substring(pi, i);
						}
						state = 1;
						fi.align = 'R';
						fi.spcc = ' ';
						fi.len = 0;
						fi.dpc = 0;
						fi.f = 'd';
					}
					++i;
					continue;
				// 1, 确认是否有 -
				case 1:
					if ('%' == cc) {
						res += '%';
						pi = ++i;
						state = 0;
						continue;
					}
					if ('-' == cc) {
						fi.align = 'L';
						++i;
					}
					state = 2;
					continue;
				// 2, 确认是否有 0  
				case 2:
					if ('0' == cc) {
						fi.spcc = '0';
						++i;
					}
					state = 3;
					continue;
				// 3 找数据宽度
				case 3:
					if (ncs.indexOf(cc) != -1) {
						ni = i;
						while (ncs.indexOf(cc = fmt.charAt(++i)) != -1)
							;
						fi.len = parseInt(fmt.substring(ni, i), 10);
						if ('.' == cc) {
							ni = ++i;
							while (ncs.indexOf(cc = fmt.charAt(i++)) != -1)
								;
							fi.dpc = parseInt(fmt.substring(ni, --i), 10);
						}
					}
					state = 4;
					continue;
				// 4, 找格式类型   
				case 4:
					arg = arguments[ai++];
					switch (cc) {
						case 'd':
							as = arg.toString(10);
							break;
						case 's':
							as = arg;
							break;
						case 'f':
							as = arg.toString(10);
							// . 的位置
							var dx = as.indexOf('.');
							if (dx == -1) {
								as = as + this.fillStr('.', fi.dpc + 1, null, 'L');
							}
							else {
								if (as.length > dx + fi.dpc) {
									as = as.substring(0, dx + fi.dpc + 1);
								}
								else {
									as = this.fillStr(as, dx + fi.dpc + 1, null, 'L');
								}
							}
							break;
						case 'x':
							as = arg.toString(16);
							break;
						case 'o':
							as = arg.toString(8);
						default:
							break;
					}
					if ('0' == fi.spcc) {
						res += this.fillStr(as, fi.len, null, fi.align);
					}
					else {
						res += this.fillStr(as, fi.len, spbs, fi.align);
					}
					pi = ++i;
					state = 0;
					break;
			}
		}
		if (i > pi)
			res += fmt.substring(pi, i);

		return res;
	};

	$hcj.openWindow = function (url, name, features, replace) {
		///	<summary>
		///	打开窗口
		///	</summary>
		///	<param name="url" type="String">
		///	目标窗口
		///	</param>
		///	<param name="name" type="String">
		///	窗口名称
		///	</param>
		///	<param name="name" type="String">
		///	窗口特征
		/// channelmode=yes|no|1|0  是否使用剧院模式显示窗口。
		/// directories=yes|no|1|0  是否添加目录按钮。
		/// fullscreen=yes|no|1|0   是否使用全屏模式显示浏览器。处于全屏模式的窗口必须同时处于剧院模式。 
		/// height=pixels           窗口文档显示区的高度。以像素计。 
		/// left=pixels             窗口的 x 坐标。以像素计。 
		/// location=yes|no|1|0     是否显示地址字段。
		/// menubar=yes|no|1|0      是否显示菜单栏。
		/// resizable=yes|no|1|0    窗口是否可调节尺寸。
		/// scrollbars=yes|no|1|0   是否显示滚动条。
		/// status=yes|no|1|0       是否添加状态栏。
		/// titlebar=yes|no|1|0     是否显示标题栏。
		/// toolbar=yes|no|1|0      是否显示浏览器的工具栏。
		/// top=pixels              窗口的 y 坐标。 
		/// width=pixels            窗口的文档显示区的宽度。以像素计。 
		///	</param>
		///	<param name="replace" type="Boolean">
		///	是否覆盖
		///	</param>
		///	<returns type="Object">打开的窗口对象</returns>
		if (features == null) { features = {}; }
		if (features.width == null) { features.width = 400; }
		if (features.height == null) { features.height = 300; }
		if (features.left == null) {
			features.left = (window.screen.availWidth - features.width) / 2
		}
		if (features.top == null) {
			features.top = (window.screen.availHeight - features.height) / 2;
		}
		var fd = function (a, d) {
			if (null != a) {
				if (1 == a || true == a || 'yes' == a) {
					return 'yes';
				}
			} else {
				if (d != null) {
					return d;
				}
			}
			return 'no';
		};
		var ft = this.format(
			'channelmode=%s,directories=%s,fullscreen=%s,location=%s,menubar=%s,resizable=%s,scrollbars=%s,status=%s,titlebar=%s,toolbar=%s,left=%d,top=%d,width=%d,height=%d',
			fd(features.channelmode),
			fd(features.directories),
			fd(features.fullscreen),
			fd(features.location),
			fd(features.menubar),
			fd(features.resizable),
			fd(features.scrollbars),
			fd(features.status),
			fd(features.titlebar),
			fd(features.toolbar),
			features.left,
			features.top,
			features.width,
			features.height);
		return window.open(url, name, ft, replace);
	};

	$hcj.setAttributes = function (src, dest, throwIfError, endIfError, valfun) {
		///	<summary>
		///	设置属性
		///	</summary>
		///	<param name="src" type="Object">
		///	源对象
		///	</param>
		///	<param name="dest" type="Object">
		///	目标对象
		///	</param>
		///	<param name="throwIfError" type="Boolean">
		///	遇到异常时是否抛出 
		///	</param>
		///	<param name="endIfError" type="Boolean">
		///	遇到异常时是否中止 
		///	</param>
		///	<param name="valfun" type="Function">
		///	用于计算结果的函数, 应带两个参数, 第一个为属性名称, 第二为属性值, 此函数的返回值将赋给目标对象的相应属性 
		///	</param>
		///	<param name="replace" type="Boolean">
		///	是否覆盖
		///	</param>
		///	<returns type="Object">打开的窗口对象</returns>
		for (var an in src) {
			try {
				if (valfun == null) {
					dest[an] = src[an];
				} else {
					dest[an] = valfun(an, src[an]);
				}
			} catch (err) {
				if (throwIfError) throw err;
				if (endIfError) break;
			}
		}
	};

	$hcj.escapeUrlChars = function (s) {
		if (s == null) {
			return null;
		}
		var fs = this.fillStr;
		return s.replace(/[`=\\\[\];',\/~!#$%^&()+|\{\}:""<>\? ]/g, function (mc) {
			return '%' + fs(mc.charCodeAt(0).toString(16), 2);
		});
	};

	//var getProp = function (obj, expr, args) {
	//	if (obj == undefined) {
	//		return expr;
	//	}
	//	if (obj == null) {
	//		return null;
	//	}
	//	if (args != null) {
	//		var i = parseInt($.trim(expr));
	//		if (!isNaN(i)) {
	//			var v = args[i + 1];
	//			if (v != undefined && v != null) {
	//				return v;
	//			}
	//		}
	//	}
	//	var v = obj[$.trim(expr)];
	//	if (v != undefined) {
	//		return v;
	//	}
	//	var index = expr.lastIndexOf('.');
	//	if (index == -1) {
	//		//var i = parseInt(expr);
	//		//if (!isNaN(i)) {
	//		//	var v = args[i + 1];
	//		//	if (v != undefined && v != null) {
	//		//		return v;
	//		//	}
	//		//}
	//		v = getProp(args[1], $.trim(expr), arguments);
	//		if (v) {
	//			return v;
	//		}

	//		return expr;
	//	}
	//	v = getProp(obj, expr.substring(0, index), args);
	//	if (v) {
	//		return v[$.trim(expr.substring(index + 1))];
	//	}

	//	return expr;
	//};

	/**
	 * 去空格
	 * @param {any} text
	 */
	$hcj.trim = function (text) {
		//return text == null ? '' : text.replace(/^\s+|\s+$/gm, '');
		return $hcj.newSStr(text).trim().val();
	};

	/**
	 * 判断是否是函数
	 * @param {any} obj
	 */
	$hcj.isFunction = function (obj) {
		return 'function' == typeof obj;
	};

	/**
	 * 获取属性
	 * @param {any} obj
	 * @param {any} key
	 * @param {any} args
	 */
	$hcj.getProp = function (obj, key, args) {

		if (obj == null || obj == undefined) {
			return null;
		}
		if ($hcj.isFunction(obj)) {
			return obj(key);
		}
		// 当前args参数并没有起作用
		// by chenf 2019-03-10
		key = $hcj.trim(key);

		if (obj.__get__) {
			return obj.__get__(key);
		}
		if (key == 'this') {
			return obj;
		}
		return obj[key];
		//return obj.__get__ ? obj.__get__(key) : obj[key];
		//var index = key.indexOf('.');
		//if (true || index == -1) {
		//	//if (args) {
		//	//	var i = parseInt(expr);
		//	//	if (!isNaN(i)) {
		//	//		return args[i + 1];
		//	//	}
		//	//}

		//	return obj.__get__ ? obj.__get__(key) : obj[key];
		//} else {
		//	var v = getProp(obj, key.substring(0, index), args);
		//	if (v) {
		//		return getProp(v, key.substring(index + 1), null);
		//	}
		//}

		//return key;
	};

	var fmtObj = function (obj, fmt) {
		if (obj == undefined || obj == null) return obj;
		var index = fmt.indexOf('|');
		if (index == -1) {
			return obj.fmt(fmt);
		}
		return fmtObj(obj.fmt(fmt.substring(0, index)), fmt.substring(index + 1));
	};

	/// <summary>
	/// 格式化
	/// </summary>
	/// <param name="format">格式化字符串</param>
	/// <param name="args">格式化参数</param>
	$hcj.basefmt = function (format, args) {
		if (arguments.length > 2) {
			throw new Error('$hcj.fmt(format, args)只允许两个参数，如果需要传递多个变量，请将数组传递给args');
		}

		var EOF = 0;

		var FST_NORMAL = 0;
		var FST_FOUND_L0 = 3;
		var FST_FOUND_L = 1;
		var FST_FOUND_R0 = 4;
		var FST_FOUND_R = 2;
		var FST_NORMAL0 = 5;

		var state = FST_NORMAL;
		var i = 0, lb = 0;
		var len = format.length;
		var s = '';

		while (i <= len) {
			var c;
			if (i == len) {
				c = EOF;
			} else {
				c = format[i];
			}

			switch (state) {
				case FST_NORMAL:
					switch (c) {
						default: break;
						case '{':
							state = FST_FOUND_L0;
							break;
						case '}':
							state = FST_FOUND_R0;
							break;
						case EOF:
							//formatter.Put(new Str(lb, fmt), ctx);
							s += format.substring(lb, i);
							break;
					}
					break;
				case FST_FOUND_L0:
					if (c == '{') {
						//formatter.Put(new Str(lb, fmt), ctx);
						s += format.substring(lb, i);
						state = FST_NORMAL;
						lb = i + 1;
					}
					else {
						//formatter.Put(new Str(lb, fmt - 1), ctx);
						s += format.substring(lb, i - 1);
						state = FST_FOUND_L;
						lb = i;
						continue;
					}
					break;
				case FST_FOUND_L:
					if ('}' == c) {
						//formatter.Format(new Str(lb, fmt), ctx);
						state = FST_NORMAL0;
						//lb = fmt + 1;
					}
					break;
				case FST_NORMAL0:
					if ('}' == c) {
						// 此时说明key里面有左花括号符号，需要对key做转义处理
						// by chenf 2020-11-12 17:18
						state = FST_FOUND_L;
					}
					else {
						//formatter.Format(new Str(lb, fmt), ctx);
						var key = format.substring(lb, i - 1);
						var index = key.indexOf(':');
						var a;
						if (index == -1) {
							a = $hcj.getProp(args, key, arguments);// || key;// args[f] || f;
							//if (a == undefined) {
							//	a = key;
							//}
						} else {
							var f = key.substring(index + 1);
							key = key.substring(0, index);
							a = $hcj.getProp(args, key, arguments); // args[f];
							//if (a == undefined) {
							//	a = f;
							//}
							if (a != null && a.fmt) {
								//a = a.fmt(ff);
								a = fmtObj(a, f);
								//if (a == undefined) {
								//	a = key;
								//}
							}
						}

						//if (a == undefined) {
						if ('undefined' == typeof (a)) {
							//s += format.substring(lb - 1, i);
						} else if (a == null) {

						} else {
							s += a;
						}
						state = FST_NORMAL;
						lb = i;
						continue;
					}
					break;
				case FST_FOUND_R0:
					if (c == '}') {
						//formatter.Put(new Str(lb, fmt), ctx);
						s += format.substring(lb, i);
						state = FST_NORMAL;
						lb = i + 1;
					}
					else {
						//formatter.Put(new Str(lb, fmt - 1), ctx);
						s += format.substring(lb, i - 1);
						state = FST_FOUND_R;
						lb = i;
						continue;
					}
					break;
				case FST_FOUND_R:
					if ('}' == c) {
						//formatter.Put(new Str(&c, 1), ctx);
						s += c; //format.substring()
						state = FST_NORMAL;
						lb = i + 1;
					}
					else {
						throw new Error($hcj.fmt('不正确的格式字符串：{this}', format));
					}
					break;
			}
			++i;
		}

		if (FST_NORMAL == state) {
			//if (i != lb) {
			//	//formatter.Put(new Str(lb, fmt), ctx);
			//	s += format.substring(lb, i);
			//}
			return s;
		}

		throw new Error($hcj.fmt('不正确的格式字符串：{this}', format));
	};

	/// <summary>
	/// 格式化。fmt支持表达式计算功能
	/// </summary>
	/// <param name="format">格式化字符串</param>
	/// <param name="args">格式化参数</param>
	$hcj.fmt = function (format, args) {
		return $hcj.basefmt(format, $hcj.newEvalCtx(args));
	};

	/// <summary>
	/// 运算符
	/// </summary>
	var Optr = {
		/// <summary>
		/// 空，没有运算符
		/// </summary>
		Empty: 0,

		/// <summary>
		/// 按位或 |
		/// </summary>
		Or: 0x018001,

		/// <summary>
		/// 按位异或 ^
		/// </summary>
		Xor: 0x028001,

		/// <summary>
		/// 按位与 &amp;
		/// </summary>
		And: 0x048001,

		/// <summary>
		/// 加 +
		/// </summary>
		Add: 0x068001,

		/// <summary>
		/// 减 -
		/// </summary>
		Sub: 0x068002,

		/// <summary>
		/// 乘 *
		/// </summary>
		Mul: 0x088001,

		/// <summary>
		/// 除 /
		/// </summary>
		Div: 0x088002,

		/// <summary>
		/// 取模 %
		/// </summary>
		Mod: 0x088003,

		/// <summary>
		/// 点 .
		/// </summary>
		Dot: 0x0F8001,

		/// <summary>
		/// 索引 []
		/// </summary>
		Idx: 0x0F8002,

		/// <summary>
		/// 函数调用, 保留
		/// </summary>
		Cal: 0x0F8003
	};

	/// <summary>
	/// part 的类型
	/// </summary>
	var PartType = {
		/// <summary>
		/// 未知
		/// </summary>
		Unknown: 0,

		/// <summary>
		/// 变量
		/// </summary>
		Var: 1,

		/// <summary>
		/// 整形
		/// </summary>
		Integer: 2,

		/// <summary>
		/// 长整形
		/// </summary>
		Long: 3,

		/// <summary>
		/// 浮点型
		/// </summary>
		Float: 4,

		/// <summary>
		/// 双精度浮点型
		/// </summary>
		Double: 5,

		/// <summary>
		/// 算术型
		/// </summary>
		Decimal: 6,

		/// <summary>
		/// 字符串
		/// </summary>
		String: 7,

		/// <summary>
		/// 括号括起来的表达式
		/// </summary>
		BracketExpression: 8,

		/// <summary>
		/// 表达式
		/// </summary>
		Expression: 9,

		/// <summary>
		/// 字符
		/// </summary>
		ConstChar: 10,

		/// <summary>
		/// 数字
		/// </summary>
		Number: 101,

		/// <summary>
		/// 标示
		/// </summary>
		Idtf: 102,

		/// <summary>
		/// 双引号
		/// </summary>
		Quot: 103,

		/// <summary>
		/// 单引号
		/// </summary>
		SingleQuot: 104,

		/// <summary>
		/// 括号
		/// </summary>
		Bracket: 105,

		/// <summary>
		/// 方括号
		/// </summary>
		FBracket: 106,

		/// <summary>
		/// 函数调用
		/// </summary>
		FunctionCall: 107
	};

	/// <summary>
	/// 获取运算符的优先级值
	/// </summary>
	/// <param name="optr"></param>
	/// <returns></returns>
	var GetOptrLevel = function (optr) {
		switch (optr) {
			case Optr.Empty:
				return 0;
			case Optr.Or:
				return 0x180;
			case Optr.Xor:
				return 0x280;
			case Optr.And:
				return 0x480;
			case Optr.Add:
				return 0x680;
			case Optr.Sub:
				return 0x680;
			case Optr.Mul:
				return 0x880;
			case Optr.Div:
				return 0x880;
			case Optr.Mod:
				return 0x880;
			case Optr.Dot:
				return 0xF80;
			case Optr.Idx:
				return 0xF80;
			default:
				throw new Error("不支持的运算符: " + optr);
		}
	};

	/// <summary>
	/// 解析一部分
	/// </summary>
	/// <param name="start">The start.</param>
	/// <param name="index">The index.</param>
	/// <param name="length">The length.</param>
	/// <param name="ctx">The CTX.</param>
	/// <param name="part">The part.</param>
	/// <returns></returns>
	var FindPart = function (start, index, length, ctx, part) {
		var state = 0;

		var ST_START = 0;
		var ST_BEG = 1;
		var lb = 0;
		var kuohao = 0;

		var lc = '\0';
		var rc = '\0';

		//part = new ExpressionPart();
		while (index < length) {
			var c = start.charAt(index); //start[index];
			switch (state) {
				case ST_START:
					if (SStr.IsWhiteSpace(c)) {
						break;
					}
					state = ST_BEG;
					lb = index;
					switch (c) {
						case '(': /*part.type = PartType.Bracket;*/ lc = '('; rc = ')'; ++kuohao; break;
						case '0':
						case '1':
						case '2':
						case '3':
						case '4':
						case '5':
						case '6':
						case '7':
						case '8':
						case '9':
						case '-':
						case '+':
							part.type = PartType.Number; break;
						case '[': /*part.type = PartType.FBracket;*/ lc = '['; rc = ']'; ++kuohao; break;
						case '"': /*part.type = PartType.Quot;*/ lc = '"'; rc = '"'; ++kuohao; break;
						case '\'': /*part.type = PartType.SingleQuot;*/ lc = '\''; rc = '\''; ++kuohao; break;
						default: part.type = PartType.Idtf; continue;
					}
					break;

				case ST_BEG:
					switch (part.type) {
						//case PartType.Quot: if (c == '"') goto __RET; break;
						//case PartType.SingleQuot: if (c == '\'') goto __RET; break;
						//case PartType.Idtf: if (c == '(') { part.type = PartType.FunctionCall; ++kuohao; } break;
						default:
							if (kuohao == 0) {
								switch (c) {
									case '+':
									case '-':
									case '*':
									case '/':
									case '%':
									case '|':
									case '^':
									case '&':
										part.exp = start.substr(lb, index - lb); //new Str(start + lb, index - lb);
										return index;
									case '.':
										if (PartType.Number == part.type && length > index && SStr.IsDigit(start[index + 1])) {
											part.type = PartType.Double;
											break;
										}
										part.exp = start.substr(lb, index - lb); //new Str(start + lb, index - lb);
										return index;
									case '[':
										part.exp = start.substr(lb, index - lb); // new Str(start + lb, index - lb);
										return index;
								}
							}
							else {
								if (c == rc) {
									if (0 == --kuohao) {
										switch (c) {
											case ']': part.type = PartType.FBracket; break;
											case ')':
												if (part.type == PartType.Idtf) {
													part.type = PartType.FunctionCall;
												}
												else {
													part.type = PartType.Bracket;
												}
												break;
											case '"': part.type = PartType.Quot; break;
											case '\'': part.type = PartType.SingleQuot; break;
										}
										//goto __RET;
										++index;
										part.exp = start.substr(lb, index - lb); //new Str(start + lb, index - lb);
										return index;
									}
								}
								else if (c == lc) {
									++kuohao;
								}

								//switch (c)
								//{
								//	case '[': if (part.type == PartType.FBracket) ++kuohao; break;
								//	case '(': if (part.type == PartType.Bracket) ++kuohao; break;
								//	case ']': if (part.type == PartType.FBracket) if (0 == --kuohao) goto __RET; break;
								//	case ')': if (part.type == PartType.Bracket) if (0 == --kuohao) goto __RET; break;
								//}
							}
							break;
					}
					break;

					//__RET:
					++index;
					part.exp = start.substr(lb, index - lb); //new Str(start + lb, index - lb);
					return index;

			}
			++index;
		}

		part.exp = start.substr(lb, index - lb); //new Str(start + lb, index - lb);
		return index;
	};

	/// <summary>
	/// 解析一部分
	/// </summary>
	/// <param name="start">The start.</param>
	/// <param name="index">The index.</param>
	/// <param name="length">The length.</param>
	/// <param name="ctx">The CTX.</param>
	/// <param name="optr">The optr.</param>
	/// <returns></returns>
	var FindOptr = function (start, index, length, ctx, optr) {
		while (index < length) {
			var c = start.charAt(index++); //start[index++];
			if (SStr.IsWhiteSpace(c)) {
				continue;
			}
			switch (c) {
				case '+': optr.optr = Optr.Add; return index;
				case '-': optr.optr = Optr.Sub; return index;
				case '*': optr.optr = Optr.Mul; return index;
				case '/': optr.optr = Optr.Div; return index;
				case '%': optr.optr = Optr.Mod; return index;
				case '.': optr.optr = Optr.Dot; return index;
				case '|': optr.optr = Optr.Or; return index;
				case '^': optr.optr = Optr.Xor; return index;
				case '&': optr.optr = Optr.And; return index;
				case '[': optr.optr = Optr.Idx; --index; return index;
				default: throw new Error("没有找到运算符");
			}
		}

		optr.optr = Optr.Empty;
		return index;
	};

	/// <summary>
	/// 计算一个表达式部分
	/// </summary>
	/// <param name="part"></param>
	/// <param name="ctx"></param>
	/// <returns></returns>
	var EvalPart = function (part, ctx) {
		//var value;

		switch (part.type) {
			case PartType.Var:
				//if (ctx.TryGetValue(ref part.exp, out value)) {
				//	return value;
				//}
				//return ctx[part.exp.val()];
				return $hcj.getProp(ctx, part.exp.val());
				break;
			case PartType.Integer:
				//Int32 i32;
				//if (part.exp.TryParseInt32(out i32)) {
				//	return i32;
				//}
				return parseInt(part.exp.val());
				break;
			case PartType.Long:
				//Int64 i64;
				//if (part.exp.TryParseInt64(out i64)) {
				//	return i64;
				//}
				return parseInt(part.exp.val());
				break;
			case PartType.Float:
				//double f;
				//if (part.exp.TryParseDouble(out f)) {
				//	return (float)f;
				//}
				return parseFloat(part.exp.val());
				break;
			case PartType.Double:
				//double d;
				//if (part.exp.TryParseDouble(out d)) {
				//	return d;
				//}
				return parseFloat(part.exp.val());
				break;
			case PartType.Decimal:
				//decimal dec;
				//if (part.exp.TryParseDecimal(out dec)) {
				//	return dec;
				//}
				return parseFloat(part.exp.val());
				break;
			case PartType.String:
				//if (Trim(ref part.exp, '"', '"')) {
				//	return part.exp.ToString();
				//}
				part.exp = part.exp.substr(1, part.exp.length - 2);
				return part.exp.val();
				break;
			case PartType.BracketExpression:
				//if (Trim(ref part.exp, '(', ')')) {
				//	part.type = PartType.Expression;
				//	return EvalPart(ref part, ctx);
				//}
				part.exp = part.exp.substr(1, part.exp.length - 2);
				part.type = PartType.Expression;
				return EvalPart(part, ctx);
				break;
			case PartType.Expression:
				//return Eval(ref part.exp, ctx);
				return $hcj.eval(part.exp.val(), ctx);
			case PartType.ConstChar:
				//if (Trim(ref part.exp, '\'', '\'')) {
				//	return part.exp[0];
				//}
				part.exp = part.exp.substr(1, part.exp.length - 2);
				return part.exp.val();
				break;
			case PartType.FBracket:
				//if (Trim(ref part.exp, '[', ']')) {
				//	return Eval(ref part.exp, ctx);
				//}

				//return ctx[part.exp.substr(1, part.exp.length - 2).val()];

				// fix bug
				// by chenf 2021-01-07 16:27
				//return $hcj.getProp(ctx, part.exp.substr(1, part.exp.length - 2).val());
				return $hcj.eval(part.exp.substr(1, part.exp.length - 2).val(), ctx);

				break;
			default:
				break;
		}

		throw new Error("无法计算：" + part.exp.val());
	};

	/// <summary>
	/// 计算
	/// </summary>
	/// <param name="optr"></param>
	/// <param name="a"></param>
	/// <param name="part"></param>
	/// <param name="ctx"></param>
	/// <returns></returns>
	var Calc = function (a, optr, part, ctx) {
		if (optr == Optr.Dot) {
			//Object v;
			//if (ObjectVarContext.TryGetValue(a, ref part.exp, out v)) {
			//	return v;
			//}

			//throw new NormalException("无法获取表达式: " + part.exp.ToString());
			//return a[part.exp.val()];
			return $hcj.getProp(a, part.exp.val());
		}
		else {
			//var b = $hcj.eval(part.exp.val(), ctx);
			var b = EvalPart(part, ctx);
			switch (optr) {
				case Optr.Add: return a + b;
				case Optr.Sub: return a - b;
				case Optr.Mul: return a * b;
				case Optr.Div: return a / b;
				case Optr.Mod: return a % b;
				case Optr.Idx: return a[b];
				case Optr.And: return a & b;
				case Optr.Dot: return a[b];
				case Optr.Or: return a | b;
				case Optr.Xor: return a ^ b;
				case Optr.Cal:
				default: throw new Error('暂时不支持的运算: ' + optr);
			}
			//return Calc(a, optr, EvalPart(ref part, ctx));
		}
	};

	var MAX_INT = 2147483647;

	/// <summary>
	/// 计算表达式
	/// </summary>
	/// <param name="expression"></param>
	/// <param name="ctx"></param>
	/// <returns></returns>
	$hcj.eval = function (expression, ctx) {
		// 当前表达式部分
		var part = {}; // ExpressionPart
		// 当前运算符
		var optr = Optr.Empty;
		// 当前结果
		var result = null;
		// 当前的运算优先级
		var level = MAX_INT;

		var start = new SStr(expression);
		var length = expression.length;
		var index = 0;

		while (index < length) {
			var left = null;
			var next = { optr: Optr.Empty };

			do {
				index = FindPart(start, index, length, ctx, part);
				index = FindOptr(start, index, length, ctx, next);
				//Str.TrimWhiteSpace(ref part.exp);
				part.exp = part.exp.trim(); //$.trim(part.exp);

				if (level < GetOptrLevel(next.optr)) {
					if (left == null) {
						left = part.exp.start;
					}
					continue;
				}
				else if (left != null) {
					part.exp = new SStr(expression, left, part.exp.end() - left);
					part.type = PartType.Expression;
					break;
				}

				switch (part.type) {
					case PartType.Number:
						part.type = PartType.Integer;
						break;
					case PartType.Idtf:
						part.type = PartType.Var;
						break;
					case PartType.Quot:
						part.type = PartType.String;
						break;
					case PartType.SingleQuot:
						part.type = PartType.ConstChar;
						break;
					case PartType.Bracket:
						part.type = PartType.BracketExpression;
						break;
					default:
						break;
				}

				break;
			} while (index < length);

			// 计算出这个部分所表达的值
			if (level == MAX_INT) {
				result = EvalPart(part, ctx);
			}
			else {
				result = Calc(result, optr.optr, part, ctx);
			}

			// 如果是第一个部分，则这个部分就是左边的操作数，否则是和左边的操作数相加，并放到左边的操作数中保存
			// 根据优先级决定是先进行当前运算还是下一个运算
			level = GetOptrLevel(next.optr);
			optr = next;
		}

		return result;
	};

	/// <summary>
	/// 下载内容
	/// </summary>
	/// <param name="url">URL</param>
	/// <param name="data">请求数据</param>
	/// <param name="method">请求方法：GET、POST等</param>
	$hcj.download = function (url, data, method) {
		// 获得url和data
		if (url && data) {
			var $form = document.createElement('form');
			document.body.appendChild($form);
			$form.action = url;
			$form.method = method || 'POST';
			$form.enctype = 'application/x-www-form-urlencoded';
			$form._target = '_blank';

			// data是string或者array/object
			if (typeof data == 'string') {
				inputs = $hcj.format('<input type="hidden" name="%s" value="" />', data);
			} else {
				for (var key in data) {
					var $hidden = document.createElement('input');
					$form.appendChild($hidden);
					$hidden.setAttribute('type', 'hidden');
					$hidden.name = key;
					$hidden.value = data[key];
				}
			}

			$form.submit();
			$form.remove();
		};
	};
})($hcj);

(function ($hcj) {

	/**
	 * 基本类型扩展
	 * @param {any} format
	 */
	Date.prototype.fmt = function (format) {
		return $hcj.formatDate(this, format);
	};

	/**
	 * 将字符串解析为日期
	 * @param {any} timeString
	 * @param {any} format
	 */
	Date.parseDate = function (timeString, format) {
		var date = $hcj.parseDate(timeString, format || $hcj.stdTimeFmt);
		if (date) {
			return date;
		}
		var t = Date.parse(timeString);
		if (!isNaN(t)) {
			return new Date(t);
		}

		return null;
		//var t = Date.parse(timeString);
		//if (isNaN(t)) {
		//	return $hcj.parseDate(timeString, format || $hcj.stdTimeFmt);
		//}
		//return new Date(t);
	};

	/**
	 * Date.from()已经弃用，请使用Date.parseDate()
	 * @param {any} timeString
	 * @param {any} format
	 */
	Date.from = function (timeString, format) {
		console.warn('Date.from()已经弃用，请使用Date.parseDate()');
		return Date.parseDate(timeString, format);
	};

	/**
	 * 字符串格式化
	 * @param {any} format
	 */
	String.prototype.fmt = function (format) {
		switch (format) {
			case 'urlenc': return encodeURIComponent(this);
			case 'urldec': return decodeURIComponent(this);
			case 'urlesc': return encodeURI(this);
			case 'urlrec': return decodeURI(this);
		}

		if (format && format.startsWith('date')) {
			if (format.startsWith('date#')) {
				return Date.parseDate(this.toString(), format.substring('date#'.length));
			} else {
				return Date.parseDate(this.toString(), null);
			}
		}
		return this;
	};

	/**
	 * 数字格式化
	 * @param {any} format
	 */
	Number.prototype.fmt = function (format) {
		switch (format) {
			case 'x': return this.toString(16);
			case 'X': return this.toString(16).toUpperCase();
			case 'o': return this.toString(8);
			case 'b': return this.toString(2);
			case 'K': return this / 1024 + 'K';
			case 'M': return this / (1024 * 1024) + 'M';
			case 'G': return this / (1024 * 1024 * 1024) + 'G';
		}
		var fi = {};
		var index = format.indexOf('.');
		if (index == -1) {
			fi.dpc = 0;
			fi.lpc = format.length;
		} else {
			//fi.dpc = parseInt(format.substring(index + 1));
			fi.dpc = format.length - index - 1;
		}
		//var x = this.toString(10);
		//// . 的位置
		//var dx = x.indexOf('.');
		//if (dx == -1) {
		//	x = x + $hcj.fillStr('.', fi.dpc + 1, null, 'L');
		//}
		//else {
		//	if (x.length > dx + fi.dpc) {
		//		x = x.substring(0, dx + fi.dpc + 1);
		//	}
		//	else {
		//		x = $hcj.fillStr(x, dx + fi.dpc + 1, null, 'L');
		//	}
		//}
		var x = this.toFixed(fi.dpc);
		
		if (fi.lpc > 0) {
			index = x.indexOf('.');
			if (index == -1) {
				index = x.length;
			} else {
				x = x.substring(0, index);
			}
			if (fi.lpc > index); {
				x = $hcj.fillStr(x, fi.lpc);
			}
		}

		return x;
	};

	//Array.prototype.fmt = function (format) {
	//	var s = null;
	//	for (var i = 0; i < this.length; ++i) {
	//		var item = this[i];
	//		var v;
	//		if (item && item.fmt) {
	//			v = item.fmt(format);
	//		} else {
	//			v = item;
	//		}
	//		if (s == null) {
	//			s = v;
	//		} else {
	//			s = s + ', ' + v;
	//		}
	//	}
	//	return s;
	//};
})($hcj);

// 导出模块
if ('undefined' != typeof (module)) {
	module.exports = $hcj;
}
