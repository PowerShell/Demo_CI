if ( test-path alias:print ) { remove-item alias:print }

set-strictmode -version latest

function ConvertTo-ScriptBlock
{
<#
.SYNOPSIS
Convert an object to a well-formatted script block.  The script block can be evaluated to re-create the object.

.DESCRIPTION
The ConvertTo-ScriptBlock function converts an object to a well-formatted script block.  The script block can be evaluated to re-create the object.

The script block is useful for both visualization and serialization.  It is formatted hierarchically to illustrate the relationship between an object and its children.  Child objects are indented relative to their parent.  The size of each indentation is controlled using the 'Indent' parameter.

Child objects are traversed until a recursive reference is detected, or until the maximum depth is reached.  The maximum depth is controlled using the 'Depth' parameter, and can be disabled with a value of 0. 

Objects are serialized by type.  Many common types are supported.  When a type is not supported, the object is replaced with '$null' and all of its properties are serialized in a comment block.

In some cases, evaluating the script block may not re-create the entire object:

  - a recursive reference was found within the object
  - the maximum object depth was reached
  - an unknown object type was encountered
  - an internal failure occurred

When this happens, a warning is issued to the caller.  In addition, during an internal failure, an error is issued.

.PARAMETER InputObject
Specifies the object to convert.  The object may also come from the pipeline.

When the object is a collection, using the InputObject parameter is not the same as piping the object to ConvertTo-ScriptBlock.  The pipeline processor invokes ConvertTo-ScriptBlock once for each object in the collection.  The result is a collection of script blocks.

.PARAMETER Indent
Specifies the amount of space used when indenting a child object underneath its parent.

.PARAMETER Depth
Specifies the maximum depth when traversing child objects.  A value of 0 disables this protective mechanism.

.INPUTS
Any object can be specified.

.OUTPUTS
System.Management.Automation.ScriptBlock

.NOTES
ALIASES

The ConvertTo-ScriptBlock function is aliased to 'ctsb' and 'dump'.


SCRIPT BLOCK INFORMATION

A script block returns the output of all the commands in the script block, either as a single object or as an array.  ConvertTo-ScriptBlock builds on this concept, and produces a block with a single command -- the inline creation of an object.  When evaluated, the object is re-created and returned.

Simple types, such as [int] and [string], have clear inline creation semantics.  They appear in script blocks as [int]123 and "a string".

Complex types, such as PSObject and .NET Collections (ArrayList, Stack, Queue, ...), require helper functions for inline creation.  The helper functions appear in the block, and are marked as private. 

.EXAMPLE
ConvertTo-ScriptBlock "hello, world"

"hello, world"


DESCRIPTION

This example shows how a string is converted to a script block.

.EXAMPLE
ConvertTo-ScriptBlock ([Guid]::NewGuid())

[Guid]"ae00223c-19b0-4ed4-b7aa-c92d2b7b4681"


DESCRIPTION

This example shows how a new GUID is converted to a script block.

.EXAMPLE
ConvertTo-ScriptBlock $PSVersionTable

@{
    CLRVersion=[Version]"2.0.50727.4952";
    BuildVersion=[Version]"6.1.7600.16385";
    PSVersion=[Version]"2.0";
    WSManStackVersion=[Version]"2.0";
    PSCompatibleVersions=@(
        [Version]"1.0",
        [Version]"2.0"
    );
    SerializationVersion=[Version]"1.1.0.1";
    PSRemotingProtocolVersion=[Version]"2.1"
}


DESCRIPTION

This example shows how a complex object is converted to a script block.  $PSVersionTable is a hash table containing details about the version of Windows PowerShell that is running on the current system.  It contains a number of System.Version objects, and an embedded array (PSCompatibleVersions).

.EXAMPLE
ConvertTo-ScriptBlock (New-Object System.Exception "sample exception")

WARNING: A problem was encountered while converting the object to a script block.  As a result, evaluating the script block may not re-create the object.  More information may be available within the text of the script block.
$null
#   [Exception]
#   Data=
#       [System.Collections.ListDictionaryInternal]
#       Count=[int]0
#       IsFixedSize=$false
#       IsReadOnly=$false
#       IsSynchronized=$false
#       Keys=
#       SyncRoot=
#       Values=
#   HelpLink=$null
#   InnerException=$null
#   Message="sample exception"
#   Source=$null
#   StackTrace=$null
#   TargetSite=$null


DESCRIPTION

This example shows how an unsupported object type (System.Excception) is converted to a script block.  The Exception object is replaced with $null, and its properties are serialized in a comment block.

Notice the warning message to the caller.

.EXAMPLE
ConvertTo-ScriptBlock $stack_of_pies

function private:CreateStack($contents) { $o = new-object System.Collections.Stack; for ($i = $contents.Length - 1; $i -ge 0; $i--) { $x = $o.Push($contents[$i]) }; ,$o }

(CreateStack @(
    "Pumpkin",
    "Blueberry",
    "Cherry",
    "Apple"
))


DESCRIPTION

This example shows how a System.Collections.Stack object is converted to a script block.  The conversion requires the use of a helper function.

The $stack_of_pies object in this example can be created using the following commands:

    $stack_of_pies = new-object System.Collections.Stack
    $stack_of_pies.Push("Apple")
    $stack_of_pies.Push("Cherry")
    $stack_of_pies.Push("Blueberry")
    $stack_of_pies.Push("Pumpkin")

Notice that the stack ordering is preserved.  'Apple', the first element pushed, is at the bottom of the stack as shown in the script block.  'Pumpkin', the last element pushed, is at the top.  The helper function inverts the array when the stack is re-created.

.EXAMPLE
ConvertTo-ScriptBlock $recursive_stack_of_pies

WARNING: A problem was encountered while converting the object to a script block.  As a result, evaluating the script block may not re-create the object.  More information may be available within the text of the script block.
function private:CreateStack($contents) { $o = new-object System.Collections.Stack; for ($i = $contents.Length - 1; $i -ge 0; $i--) { $x = $o.Push($contents[$i]) }; ,$o }

(CreateStack @(
    "Pumpkin",
    "Blueberry",
    (CreateStack @(
#       -- contents removed (recursive reference detected) --
#       -- parent object '(CreateStack @( ... ))' of type [System.Collections.Stack] at depth 0 --
    )),
    "Cherry",
    "Apple"
))


DESCRIPTION

This example builds on the previous example, showing a similar stack.  In this example, the middle of the stack contains a recursive reference.  That is, one of the elements on the stack refers back to the stack itself.

When a recursive element is encountered, the recursion chain is broken and a descriptive message is put in its place.  The message identifies the target of the recursive reference.  The target is always a parent object.

The depth number is a 0-based index, starting from the top-level object, and moving down toward to the point of recursion.  In this example, the message refers to depth 0 which is the top-level object.

The $recursive_stack_of_pies object in this example can be created using the following commands:

    $recursive_stack_of_pies = new-object System.Collections.Stack
    $recursive_stack_of_pies.Push("Apple")
    $recursive_stack_of_pies.Push("Cherry")
    $recursive_stack_of_pies.Push($recursive_stack_of_pies)
    $recursive_stack_of_pies.Push("Blueberry")
    $recursive_stack_of_pies.Push("Pumpkin")

.EXAMPLE
ConvertTo-ScriptBlock $PSVersionTable -Indent 8

@{
        CLRVersion=[Version]"2.0.50727.4952";
        BuildVersion=[Version]"6.1.7600.16385";
        PSVersion=[Version]"2.0";
        WSManStackVersion=[Version]"2.0";
        PSCompatibleVersions=@(
                [Version]"1.0",
                [Version]"2.0"
        );
        SerializationVersion=[Version]"1.1.0.1";
        PSRemotingProtocolVersion=[Version]"2.1"
}


DESCRIPTION

This example shows how to control the amount of space used when indenting a child object underneath its parent.

.EXAMPLE
ConvertTo-ScriptBlock $PSVersionTable -Depth 1

WARNING: A problem was encountered while converting the object to a script block.  As a result, evaluating the script block may not re-create the object.  More information may be available within the text of the script block.
@{
    CLRVersion=[Version]"2.0.50727.4952";
    BuildVersion=[Version]"6.1.7600.16385";
    PSVersion=[Version]"2.0";
    WSManStackVersion=[Version]"2.0";
    PSCompatibleVersions=@(
#       -- contents removed (maximum object depth reached) --
    );
    SerializationVersion=[Version]"1.1.0.1";
    PSRemotingProtocolVersion=[Version]"2.1"
}


DESCRIPTION

This example shows how to control the maximum object depth when converting complex objects.  The depth number is 0-based, starting from the top-level object.  As child objects are visited, the depth increases.

In this example, the hash table (@{ ... }) is at depth 0.  The named values in the hash table (CLRVersion, BuildVersion, ...) are at depth 1.  The contents of the PSCompatibleVersions array are at depth 2.

With the maximum object depth set to 1, objects of depth 2 and above are replaced with a descriptive message. 

Notice the warning message to the caller.

.LINK
http://codebox/psvis

.LINK
about_Script_Blocks
#>

[CmdletBinding()]
Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[AllowNull()]
	[AllowEmptyString()]
	[AllowEmptyCollection()]
	[object]$InputObject,

	[UInt32]$Indent = 4, 

	[UInt32]$Depth = 20)

	Process
	{	
		$dump_state = @{
			scriptable = $true;			#  flag indicating whether or not the output script will re-create the input object
			indent = $Indent;			#  number of spaces to indent a single child object
			margin = 0;					#  current margin
			comment_count = 0;			#  counter to track how many layers are dumping within a comment block
			context_stack = @();		#  stack of context objects being actively dumped
			maximum_depth = $Depth;		#  limit on how deep the dumper will go when traversing child objects
			helpers = @{};				#  collection of helper functions to append to the dump output
		}

		$object_data = (DispatchObject $dump_state $InputObject $null $null) -join "`n"
		$helper_data = (SerializeHelpers $dump_state) -join "`n"

		if ($helper_data -ne $null -and $helper_data.Length -gt 0)
		{
			$str = $helper_data + "`n`n" + $object_data
		}
		else
		{
			$str = $object_data
		}

		if (-not $dump_state["scriptable"])
		{
			write-warning "A problem was encountered while converting the object to a script block.  As a result, evaluating the script block may not re-create the object.  More information may be available within the text of the script block."
		}

		[ScriptBlock]::Create($str)
	}
}


##
##  module state
##

$bug_report_link = "http://codebox/psvis/WorkItem/List.aspx"
$handler_array = $null
$handler_generic = $null
$handlers_uncommented = @{}
$handlers_commented = @{}
$generic_customizations = @{}
$ps_type_accelerators = @{}
$system_namespace = "System."

function Initialize 
{
	new-alias -name "ctsb" -value "ConvertTo-ScriptBlock" -scope script
	new-alias -name "dump" -value "ConvertTo-ScriptBlock" -scope script

	$script:handler_array = CreateHandler "System.Array" $null "DumpArray" "@(" ")" -is_complex
	$script:handler_generic = CreateHandler "" $null "DumpGeneric" $null $null -is_complex -is_generic

	$script:handlers_uncommented = @{}
	$script:handlers_commented = @{}
	RegisterHandler (CreateHandler "System.Collections.Hashtable" $null "DumpHashtable" "@{" "}" -is_complex)
	RegisterHandler (CreateHandler "system.String" $null "DumpString")
	RegisterHandler (CreateHandler "system.Char" $null "DumpString")
	RegisterHandler (CreateHandler "System.Management.Automation.ScriptBlock" $null "DumpScriptBlock")
	RegisterHandler (CreateHandler "System.SByte" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Byte" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Int16" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.UInt16" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Int32" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.UInt32" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Int64" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.UInt64" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.IntPtr" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.UIntPtr" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Single" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Double" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.Decimal" $null "DumpRaw")
	RegisterHandler (CreateHandler "System.DateTimeKind" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.Guid" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.TimeSpan" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.Version" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.Uri" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.Net.IPAddress" $null "DumpRawQuoted")
	RegisterHandler (CreateHandler "System.DateTime" $null "DumpDateTime")
	RegisterHandler (CreateHandler "System.Boolean" $null "DumpBoolean")
	RegisterHandler (CreateHandler "System.Xml.XmlDocument" $null "DumpXml")
	RegisterHandler (CreateHandler "System.Type" $null "DumpType")
	RegisterHandler (CreateHandler "System.RuntimeType" $null "DumpType")
	RegisterHandler -uncommented_only (CreateHandler "System.Collections.ArrayList" $null "DumpArrayList" "(CreateArrayList @(" "))" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Collections.BitArray" $null "DumpBitArray" "(CreateBitArray @(" "))" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Collections.Queue" $null "DumpQueue" "(CreateQueue @(" "))" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Collections.SortedList" $null "DumpSortedList" "(CreateSortedList @{" "})" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Collections.Stack" $null "DumpStack" "(CreateStack @(" "))" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Text.RegularExpressions.Regex" $null "DumpRegex" "(CreateRegex @(" "))" -is_complex)
	RegisterHandler -uncommented_only (CreateHandler "System.Management.Automation.PSCustomObject" "PredPSObject" "DumpPSObject" "(CreatePSObject @(" "))" -is_complex)

	$script:generic_customizations = @{}
	RegisterGenericCustomization "System.Collections.ArrayList" "CustomizeCollection"
	RegisterGenericCustomization "System.Collections.Queue" "CustomizeCollection"
	RegisterGenericCustomization "System.Collections.Stack" "CustomizeCollection"
	RegisterGenericCustomization "System.Collections.BitArray" "CustomizeBitArray"
	RegisterGenericCustomization "System.Collections.SortedList" "CustomizeSortedList"

	$script:ps_type_accelerators = @{}
	$type_accelerators = @{}  #([type]::gettype("System.Management.Automation.TypeAccelerators"))::Get
	foreach ($shortcut_type in $type_accelerators.Keys)
	{
		$full_type_name = $type_accelerators[$shortcut_type].ToString()
		$script:ps_type_accelerators[$full_type_name] = $shortcut_type
	}
}



##
##  framework
##

function ReportInternalError([Hashtable]$dump_state, [string]$message)
{
	$str = "Internal error."
	if (-not [string]::IsNullOrEmpty($message))
	{
		$str += "  " + $message
	}
	$str += "  The script block may contain errors.  Please submit a bug report to '" + $script:bug_report_link + "'."

	write-error $str

	if ($dump_state -ne $null)
	{
		$dump_state["scriptable"] = $false
	}
}


function CreateHandler([string]$type_name, [string]$predicate, [string]$function, [string]$prefix, [string]$suffix, [switch]$is_complex, [switch]$is_generic)
{
	$handler = new-object psobject
	add-member NoteProperty -Name "type_name" -Value $type_name -InputObject $handler
	add-member NoteProperty -Name "predicate" -Value $predicate -InputObject $handler
	add-member NoteProperty -Name "function" -Value $function -InputObject $handler
	add-member NoteProperty -Name "prefix" -Value $prefix -InputObject $handler
	add-member NoteProperty -Name "suffix" -Value $suffix -InputObject $handler
	add-member NoteProperty -Name "is_complex" -Value $is_complex -InputObject $handler
	add-member NoteProperty -Name "is_generic" -Value $is_generic -InputObject $handler

	$handler
}


function RegisterHandler($handler, [switch]$commented_only, [switch]$uncommented_only)
{
	if ($commented_only -and $uncommented_only)
	{
		ReportInternalError $null "An attempt was made to register a type handler using conflicting switches: commented_only and uncommented_only."
	}
	elseif ($commented_only)
	{
		$script:handlers_commented[$handler.type_name.ToLower()] = $handler
	}
	elseif ($uncommented_only)
	{
		$script:handlers_uncommented[$handler.type_name.ToLower()] = $handler
	}
	else
	{
		$script:handlers_commented[$handler.type_name.ToLower()] = $handler
		$script:handlers_uncommented[$handler.type_name.ToLower()] = $handler
	}
}


function GetHandler([Hashtable]$dump_state, $context)
{
	if ($dump_state["comment_count"] -gt 0)
	{
		$script:handlers_commented[$context.type_name.ToLower()]
	}
	else
	{
		$script:handlers_uncommented[$context.type_name.ToLower()]
	}
}


function RegisterGenericCustomization([string]$type_name, [string]$customization)
{
	$script:generic_customizations[$type_name.ToLower()] = $customization
}


function GetGenericCustomization([string]$type_name)
{
	$script:generic_customizations[$type_name.ToLower()]
}


function CreateObjectContext([Hashtable]$dump_state, [object]$o, [string]$prefix, [string]$suffix)
{
	$context = new-object psobject
	add-member NoteProperty -Name "o" -Value $o -InputObject $context
	add-member NoteProperty -Name "ref" -Value ([ref]$o) -InputObject $context
	add-member NoteProperty -Name "prefix" -Value $prefix -InputObject $context
	add-member NoteProperty -Name "suffix" -Value $suffix -InputObject $context

	# collect type information for the object.
	if ($o -eq $null)
	{
		# $null objects don't have type information.
		add-member NoteProperty -Name "type_name" -Value "" -InputObject $context
		add-member NoteProperty -Name "base_type_name" -Value "" -InputObject $context
		add-member NoteProperty -Name "resolved_type_name" -Value "" -InputObject $context
	}
	else
	{
		# the GetType() method, found on nearly all objects, yields the most fidelity.
		# some objects, such as those in powershell's Mobile Object Model, don't support 
		# this method, hence the try/catch block.
		try
		{
			$type = $o.GetType()
			add-member NoteProperty -Name "type_name" -Value $type.FullName -InputObject $context
			if ($type.BaseType -ne $null)
			{
				add-member NoteProperty -Name "base_type_name" -Value $type.BaseType.FullName -InputObject $context
			}
			else
			{
				# there is no base type.  use the object type as the base type.
				add-member NoteProperty -Name "base_type_name" -Value $type.FullName -InputObject $context
			}
		}
		catch 
		{
			# fall back on get-member to retrieve type information.  it returns a record for
			# each child member, and the records all contain type information about the object.
			# the type information is identical across all member records.
			#
			# base type information is not available through get-member.  assume that in these
			# cases where GetType() is missing, there is no base type.  use the object type as
			# the base type.
			$members = @(get-member -inputobject $o)
			if ($members -ne $null -and $members.Length -gt 0 -and $members[0].TypeName -ne $null)
			{
				add-member NoteProperty -Name "type_name" -Value $members[0].TypeName -InputObject $context
				add-member NoteProperty -Name "base_type_name" -Value $members[0].TypeName -InputObject $context
			}
			else
			{
				ReportInternalError $dump_state "Unable to collect type information for the given object."
			}
		}

		# try to resolve the type name using a list of known "powershell type accelerators".
		# these are effectively type aliases.  e.g. [System.Int32] maps to [int].
		$resolved_type_name = $script:ps_type_accelerators[$context.type_name]
		if ([string]::IsNullOrEmpty($resolved_type_name))
		{
			# if the type is in the system namespace, remove the "system." prefix.  powershell
			# recognizes classes and structures from the system namespace without fully qualified
			# type name references.
			if ($context.type_name.StartsWith($script:system_namespace))
			{
				$index_of_dot = $context.type_name.IndexOf(".")
				if ($index_of_dot -ge 0 -and $index_of_dot -eq $context.type_name.LastIndexOf("."))
				{
					$resolved_type_name = $context.type_name.Substring($script:system_namespace.Length)
				}
			}
		}

		if ([string]::IsNullOrEmpty($resolved_type_name))
		{
			# the type name cannot be resolved
			$resolved_type_name = $context.type_name
		}

		add-member NoteProperty -Name "resolved_type_name" -Value $resolved_type_name -InputObject $context
	}

	$context
}


function DispatchObject([Hashtable]$dump_state, [object]$o, [string]$prefix, [string]$suffix)
{
	if ($o -eq $null)
	{
		# null values don't carry type information, which means they cannot be dispatched 
		# through the handler table.
		Print $dump_state ($prefix + '$null' + $suffix)
	}
	else
	{
		$context = CreateObjectContext $dump_state $o $prefix $suffix

		# arrays are dispatched by their base type (system.array) rather than their actual
		# type (object[], byte[], ...).  the assumption is that no one will be deriving from
		# System.Array to make their own type.
		if ($context.base_type_name -eq "System.Array")
		{
			$handler = $script:handler_array
		}
		else
		{
			$handler = GetHandler $dump_state $context
			if ($handler -ne $null -and -not [string]::IsNullOrEmpty($handler.predicate))
			{
				if (-not (& $handler.predicate $dump_state $context))
				{
					$handler = $null
				}
			}

			if ($handler -eq $null)
			{
				# the object type is not recognized.  dump it using a generic handler.
				$handler = $script:handler_generic
			}
		}

		add-member NoteProperty -Name "handler" -Value $handler -InputObject $context

		if ($handler.is_complex)
		{
			DispatchComplexObject $dump_state $context
		}
		else
		{
			DispatchSimpleObject $dump_state $context
		}
	}
}


function DispatchComplexObject([Hashtable]$dump_state, $context)
{
	$handler = $context.handler

	$prefix = $context.prefix + $handler.prefix
	$suffix = $handler.suffix + $context.suffix

	if ($handler.is_generic)
	{
		# the object type is not recognized, and will be dumped in a comment block
		# via the generic handler.  the object will be replaced with $null.
		if ($dump_state["comment_count"] -gt 0)
		{
			# a comment block is in effect. don't print the '$null' placeholder, as
			# it is unnecessary and confusing.  also, don't print the suffix.  it 
			# makes no sense without the '$null' placeholder.
			$prefix = $context.prefix
			$suffix = $null
		}
		else
		{
			$prefix = $context.prefix + '$null' + $context.suffix
			$suffix = $null
		}
	}

	if ($prefix -ne $null -and $prefix -ne "")
	{
		Print $dump_state $prefix
	}

	Indent $dump_state

	$recursion_index = GetIndexOfRecursiveReference $dump_state $context.ref
	if ($recursion_index -ge 0)
	{
		# record the fact a cycle was found in the object graph
		$dump_state["scriptable"] = $false

		$recursion_context = ($dump_state["context_stack"])[$recursion_index]
		$recursion_prefix = $recursion_context.prefix + $recursion_context.handler.prefix
		$recursion_suffix = $recursion_context.handler.suffix + $recursion_context.suffix

		$recursion_message = "-- parent object"
		if (-not ([string]::IsNullOrEmpty($recursion_prefix) -and [string]::IsNullOrEmpty($recursion_suffix)))
		{
			$recursion_message += (" '{0} ... {1}'" -f ($recursion_prefix, $recursion_suffix))
		}
		$recursion_message += " of type [" + $recursion_context.resolved_type_name + "] at depth " + $recursion_index + " --"

		Comment $dump_state
		Print $dump_state "-- contents removed (recursive reference detected) --"
		Print $dump_state $recursion_message
		Uncomment $dump_state
	}
	else
	{
		if (PushContext $dump_state $context)
		{
			DispatchSimpleObject $dump_state $context
			PopContext $dump_state
		}
		else
		{
			# record the fact the maximum object depth was exceeded
			$dump_state["scriptable"] = $false

			Comment $dump_state
			Print $dump_state "-- contents removed (maximum object depth reached) --"
			Uncomment $dump_state
		}
	}

	Unindent $dump_state

	if ($suffix -ne $null -and $suffix -ne "")
	{
		Print $dump_state $suffix
	}
}


function DispatchSimpleObject([Hashtable]$dump_state, $context)
{
	& $context.handler.function $dump_state $context
}


function Indent([Hashtable]$dump_state)
{
	$dump_state["margin"] += $dump_state["indent"]
}


function Unindent([Hashtable]$dump_state)
{
	$dump_state["margin"] -= $dump_state["indent"]
}


function Comment([Hashtable]$dump_state)
{
	$dump_state["comment_count"]++
}


function Uncomment([Hashtable]$dump_state)
{
	$dump_state["comment_count"]--
}


function Print([Hashtable]$dump_state, [string]$data)
{
	$margin = $dump_state["margin"]
	if ($dump_state["comment_count"] -gt 0)
	{
		if ($margin -ge 2)
		{
			$margin -= 2
		}
		"# " + "".PadLeft($margin) + $data
	}
	else
	{
		"".PadLeft($margin) + $data
	}
}


function IsDoubleRef([ref]$r)
{
	$double_ref = $false
	if ($r.Value -ne $null)
	{
		$members = @(get-member -InputObject $r.Value)
		if ($members -ne $null -and $members.Length -gt 0)
		{
			$double_ref = $members[0].TypeName -eq "System.Management.Automation.PSReference"
		}
	}
	$double_ref
}


function DoRefsMatch([ref]$r1, [ref]$r2)
{
	# use [Object]::ReferenceEquals(r1, r2) to compare the underlying object
	# pointer in each reference.
	#
	# [Object]::ReferenceEquals() can only handle references to objects.  It
	# cannot handle references to references.  In those cases, the -eq operator
	# will be used to compare the underlying references.
	#
	# Consider this example:
	#
	#     $x = 1234
	#     $y = [ref]$x
	#     $x = [ref]$y
	#
	# This creates a circular reference: x -> y -> x -> y ...
	#
	# $x.Value refers to $y.  $y.Value refers to $x.  Dereferencing $x 
	# twice leads back to $x:
	#
	#     $x -eq $x               ====> $true
	#     $x -eq $x.Value         ====> $false
	#     $x -eq $x.Value.Value   ====> $true
	#
	# The [ref] objects refer to each other, and -eq can be used to tell them
	# apart.  This fills in the missing behavior from [Object]::ReferenceEquals.

	$r1_double_ref = IsDoubleRef $r1
	$r2_double_ref = IsDoubleRef $r2
	if ($r1_double_ref -and $r2_double_ref)
	{
		# compare the underlying reference objects, which are part of the object structure
		# being dumped.  they will not change, and will refer to each other (eventually)
		# in the case of a recursively defined object.
		#
		# do not compare the references themselves, as they are likely to be different
		# reference objects.  this is true even when they refer to the same underlying
		# object.
		$r1.Value -eq $r2.Value
	}
	elseif ($r1_double_ref -or $r2_double_ref)
	{
		# one of the references is a double-ref, the other is not.  they cannot be equal.
		$false
	}
	else
	{
		[Object]::ReferenceEquals($r1.Value, $r2.Value)
	}
}


function GetIndexOfRecursiveReference([Hashtable]$dump_state, [ref]$r)
{
	$index = 0
	foreach ($context in $dump_state["context_stack"])
	{
		if (DoRefsMatch $context.ref $r)
		{
			$index
			return
		}
		$index++
	}

	-1
}


function PushContext([Hashtable]$dump_state, $context)
{
	if ($dump_state["maximum_depth"] -gt 0 -and
		$dump_state["context_stack"].Length -ge $dump_state["maximum_depth"])
	{
		$false
	}
	else
	{
		$dump_state["context_stack"] += $context
		$true
	}
}


function PopContext([Hashtable]$dump_state)
{
	$stack = $dump_state["context_stack"]
	if ($stack.Length -gt 0)
	{
		$stack_updated = @()
		for ($index = 0; $index -lt ($stack.Length - 1); $index++)
		{
			$stack_updated += $stack[$index]
		}
		
		$dump_state["context_stack"] = $stack_updated
	}
}


function RegisterHelper([Hashtable]$dump_state, [string]$helper)
{
	$func = get-item function:\$helper
	if ($func -ne $null)
	{
		($dump_state["helpers"])[$helper.ToLower()] = $func
	}
	else
	{
		ReportInternalError $dump_state "An attempt was made to register a helper function named '$helper', but that function does not exist."
	}
}


function SerializeHelpers([Hashtable]$dump_state)
{
	$helpers = $dump_state["helpers"]
	foreach ($helper in $helpers.Keys)
	{
		SerializeFunctionAsPrivate $helpers[$helper]
	}
}


function SerializeFunctionAsPrivate($func)
{
	# assume a simple function definition.  don't handle parameter types,
	# don't handle anything related to advanced functions, such as parameter
	# sets, attributes, and aliases.
	$str = "function private:" + $func.Name
	if ($func.Parameters -ne $null -and $func.Parameters.Count -gt 0)
	{
		$str += "("
		$first_param = $true
		foreach ($param_name in $func.Parameters.Keys)
		{
			if ($first_param)
			{
				$first_param = $false
			}
			else
			{
				$str += ", "
			}
			$str += '$' + $param_name	
		}
		$str += ")"
	}

	# strip off the 'param(' block at the front of the definition.
	# always on its own line at the start of the definition.
	$start_second_line = $func.Definition.IndexOf("`n")
	$body = $func.Definition.Substring($start_second_line + 1).Trim()

	$str + " { " + $body + " }"
}



##
##  type-specific handlers and customizations
##

function DumpArray([Hashtable]$dump_state, $context)
{
	DumpArrayObject $dump_state $context.o
}


function DumpArrayObject([Hashtable]$dump_state, $o)
{
	$array = @($o)
	$element_suffix = ","
	for ($i = 0; $i -lt $array.Length; $i++)
	{
		if ($i -eq ($array.Length - 1))
		{
			$element_suffix = $null
		}
		DispatchObject $dump_state $array[$i] $null $element_suffix
	}
}


function DumpGeneric([Hashtable]$dump_state, $context)
{
	# this object's type is unrecognized.  re-creating it will be impossible
	# because the construction semantics are unknown.
	#
	# replace the object with '$null', and dump its property members out
	# using a multi-line comment block:
	#
	#     $null  
	#     #   [Fabrikam.Phone]
	#     #   Connected=[bool]$true
	#     #   SpeedDial=@(
	#     #       "5551234",
	#     #       "5559988"
	#     #   )

	# record the fact the an unscriptable object was encountered
	$dump_state["scriptable"] = $false

	# collect information on object members, and any customizations
	# required when printing this object.
	$members = @(get-member -MemberType Properties -InputObject $context.o)

	$members_to_skip = @{}
	$members_to_add = @{}

	$customization = GetGenericCustomization $context.type_name
	if ($customization -ne $null -and $customization -ne "")
	{
		& $customization $context $members_to_skip $members_to_add
	}

	# see if there's any data to display.  if not, don't print the type.
	# leave the display completely empty.
	if ($members.Length -le 0 -and $members_to_skip.Count -le 0 -and $members_to_add.Count -le 0)
	{
		return
	}
		
	Comment $dump_state
	Print $dump_state ("[" + $context.resolved_type_name + "]")

	foreach ($member in $members)
	{
		if (-not $members_to_skip.ContainsKey($member.Name))
		{
			DispatchObject $dump_state $context.o.($member.Name) ($member.Name + "=") $null
		}
	}

	foreach ($member_name in $members_to_add.Keys)
	{
		DispatchObject $dump_state $members_to_add[$member_name] ($member_name + "=") $null
	}

	Uncomment $dump_state
}


function DumpHashtable([Hashtable]$dump_state, $context)
{
	$array = @($context.o.Keys)
	$element_suffix = ";"
	for ($i = 0; $i -lt $array.Length; $i++)
	{
		$key = $array[$i]
		if ($i -eq ($array.Length - 1))
		{
			$element_suffix = $null
		}
		DispatchObject $dump_state $context.o[$key] ($key + "=") $element_suffix
	}
}


function DumpString([Hashtable]$dump_state, $context)
{
	# this method serializes a string, such that it can survive a roundtrip though a scriptblock.
	# when the block is evaluated, the string is re-created.  it should be identical to the 
	# original string.  furthermore, the serialized version of the string (held in the block),
	# should be human-readable (e.g. not filled with numeric character codes, binary data, ...).

	# the output of this method will be code that embodies a double-quoted string.  that means the
	# rules of character escaping and variable substitution are in effect.
	$s = $context.o.ToString()

	# start by escaping the escape character
	$s = $s.Replace('`', '``')

	# escape embedded single-quote characters that might prematurely terminate the string
	$s = $s.Replace("'", "`'")

	# escape variable references so they are not evaluated when the scriptblock is executed
	$s = $s.Replace('$', '`$')

	# scriptblocks eat tabs, for some reason.  preserve each tab by replacing it with an
	# escape sequence.  the sequence will be evaluated when the scriptblock runs.
	$s = $s.Replace("`t", '`t')

	# replace all other special characters with their escape sequences.  this is not strictly
	# necessary, but it does help to reveal with contents of the string.  the assumption here
	# is that most consumers of this library will be more interested in seeing the contents,
	# and less interested in seeing the final rendered form of the string.
	$s = $s.Replace("`0", '`0')
	$s = $s.Replace("`a", '`a')
	$s = $s.Replace("`b", '`b')
	$s = $s.Replace("`f", '`f')
	$s = $s.Replace("`v", '`v')
	$s = $s.Replace("`r", '`r')

	# break the string up into an array of lines in preparation for output
	$lines = $s -split "`n"

	# finally, print the string
	$resolved_type_name = ""
	if ($context.type_name -ne "system.string")
	{
		$resolved_type_name = "[" + $context.resolved_type_name + "]"
	}

	if ($lines.Length -eq 1)
	{
		Print $dump_state ($context.prefix + $resolved_type_name + "'" + $lines[0] + "'" + $context.suffix)
	}
	else
	{
		Print $dump_state ($context.prefix + $resolved_type_name + "@" + "'")

		# do not indent the contents of the here-string, or the terminating marker.
		# any indentation will become part of the here-string during deserialization.
		$margin = $dump_state["margin"]
		$dump_state["margin"] = 0
		foreach ($line in $lines)
		{
			Print $dump_state $line
		}
		Print $dump_state ("'" + "@" + $context.suffix)
		$dump_state["margin"] = $margin
	}
}


function DumpScriptBlock([Hashtable]$dump_state, $context)
{
	# serialize the script block.  cleanup leading and trailing blank lines.
	# replace tabs with spaces in preparation for finding the left margin
	# for proper indentation.
	$strings = $context.o.ToString().Replace("`r`n","`n") -split "`n"
	$strings = @(TrimFirstAndLastStringIfEmpty $strings)
	$strings = @(ExpandLeadingTabsToSpaces $strings)

	# find the width of the left margin.  trim the margin space from each
	# line, shifting the block as far left as possible without losing data.
	$shortest_block_indent = GetLengthOfShortestIndentation $strings
	if ($shortest_block_indent -gt 0)
	{
		$strings_trimmed = @()
		foreach ($string in $strings)
		{
			if ($string -ne $null -and $shortest_block_indent -le $string.Length)
			{
				$string = $string.Substring($shortest_block_indent)
			}
			$strings_trimmed += $string
		}
		$strings = $strings_trimmed
	}

	# finally, print the script block
	Print $dump_state ($context.prefix + "{")
	Indent $dump_state
	foreach ($string in $strings)
	{
		Print $dump_state $string
	}
	Unindent $dump_state
	Print $dump_state ("}" + $context.suffix)
}


function TrimFirstAndLastStringIfEmpty([string[]]$array)
{
	$array_trimmed = @()
	if ($array -ne $null -and $array.Length -gt 0)
	{
		$start = 0
		if ($array[0] -eq $null -or $array[0].Trim(" `t`r`n") -eq "")
		{
			$start++
		}

		$end = $array.Length - 1
		if ($array[$end] -eq $null -or $array[$end].Trim(" `t`r`n") -eq "")
		{
			$end--
		}

		if ($start -le $end)
		{
			$array_trimmed = $array[$start .. $end]
		}
	}
	$array_trimmed
}


function ExpandLeadingTabsToSpaces([string[]]$array)
{
	$array_expanded = @()
	foreach ($string in $array)
	{
		$string_expanded = ""
		for ($i = 0; $i -lt $string.Length; $i++)
		{
			if ($string[$i] -eq " ")
			{
				$string_expanded += " "
			}
			elseif ($string[$i] -eq "`t")
			{
				$string_expanded += "".PadLeft(8 - ($string_expanded.Length % 8))
			}
			else
			{
				$string_expanded += $string.Substring($i)
				break
			}
		}

		$array_expanded += $string_expanded
	}
	$array_expanded
}


function GetLengthOfShortestIndentation([string[]]$array)
{
	$first_line = $true
	$shortest_indent = 0

	foreach ($string in $array)
	{
		# ignore blank/empty lines

		if ($string -ne $null -and $string.Trim(" `t").Length -gt 0)
		{
			$indent = 0
			if ($string -match "^ +")
			{
				$indent = $matches[0].Length
			}

			if ($first_line -or $shortest_indent -gt $indent)
			{
				$shortest_indent = $indent
				$first_line = $false
			}
		}
	}

	$shortest_indent
}


function DumpRaw([Hashtable]$dump_state, $context)
{
	#Print $dump_state ($context.prefix + "[" + $context.resolved_type_name + "]" + $context.o.ToString() + $context.suffix)
    Print $dump_state ($context.prefix + $context.o.ToString() + $context.suffix)
}


function DumpRawQuoted([Hashtable]$dump_state, $context)
{
	#Print $dump_state ($context.prefix + "[" + $context.resolved_type_name + ']"' + $context.o.ToString() + '"' + $context.suffix)
    Print $dump_state ($context.prefix + "'" + $context.o.ToString() + "'" + $context.suffix)
}


function DumpBoolean([Hashtable]$dump_state, $context)
{
	if ($context.o)
	{
		Print $dump_state ($context.prefix + '$true' + $context.suffix)
	}
	else
	{
		Print $dump_state ($context.prefix + '$false' + $context.suffix)
	}
}


function DumpDateTime([Hashtable]$dump_state, $context)
{
	Print $dump_state ($context.prefix + '[' + $context.resolved_type_name + "]'" + $context.o.ToString("O") + "'" + $context.suffix)
}


function DumpXml([Hashtable]$dump_state, $context)
{
	# serialize the XmlDocument object using an XmlTextWriter
	# backed by a StringBuilder.  collect the results, and hand
	# them off to the string dumper.

	$text_writer = $null
	$writer = $null
	$str = ""
	try
	{
		$text_writer = new-object System.IO.StringWriter

		$writer = new-object system.Xml.XmlTextWriter @($text_writer)
		$writer.Formatting = [System.Xml.Formatting]::Indented
		$writer.Indentation = $dump_state["indent"]

		$context.o.WriteTo($writer)
		$str = $text_writer.ToString().Replace("`r`n","`n")
	}
	finally
	{
		if ($text_writer -ne $null)
		{
			$text_writer.Close()
			$text_writer.Dispose()
		}
		if ($writer -ne $null)
		{
			$writer.Close()
		}
	}

	# replace the XmlDocument object with its string equivalent.  leave the
	# type information in place, as it is needed by the string dumper.

	add-member NoteProperty -Name "o" -Value $str -InputObject $context -Force
	add-member NoteProperty -Name "ref" -Value ([ref]$str) -InputObject $context -Force

	DumpString $dump_state $context
}


function DumpType([Hashtable]$dump_state, $context)
{
	Print $dump_state ($context.prefix + "[" + $context.o.FullName + "]" + $context.suffix)
}


function CreateArrayList($contents) { $o = new-object System.Collections.ArrayList; $contents | % { $x = $o.Add($_) }; ,$o }

function DumpArrayList([Hashtable]$dump_state, $context)
{
	DumpArray $dump_state $context
	RegisterHelper $dump_state "CreateArrayList"
}


function CreateBitArray($contents) { $o = new-object System.Collections.BitArray @($contents.Length); for ($i = 0; $i -lt $contents.Length; $i++) { $o[$i] = $contents[$i] }; ,$o }

function DumpBitArray([Hashtable]$dump_state, $context)
{
	DumpArray $dump_state $context
	RegisterHelper $dump_state "CreateBitArray"
}


function CreateQueue($contents) { $o = new-object System.Collections.Queue; $contents | % { $x = $o.Enqueue($_) }; ,$o }

function DumpQueue([Hashtable]$dump_state, $context)
{
	DumpArray $dump_state $context
	RegisterHelper $dump_state "CreateQueue"
}


function CreateSortedList($contents) { $o = new-object System.Collections.SortedList; $contents.Keys | % { $x = $o.Add($_, $contents[$_]) }; ,$o }

function DumpSortedList([Hashtable]$dump_state, $context)
{
	DumpHashtable $dump_state $context
	RegisterHelper $dump_state "CreateSortedList"
}


function CreateStack($contents) { $o = new-object System.Collections.Stack; for ($i = $contents.Length - 1; $i -ge 0; $i--) { $x = $o.Push($contents[$i]) }; ,$o }

function DumpStack([Hashtable]$dump_state, $context)
{
	DumpArray $dump_state $context
	RegisterHelper $dump_state "CreateStack"
}


function CreateRegex($contents) { ,(new-object System.Text.RegularExpressions.Regex @($contents[0], $contents[1])) }

function DumpRegex([Hashtable]$dump_state, $context)
{
	DispatchObject $dump_state $context.o.ToString() $null ","
	DispatchObject $dump_state ([int]$context.o.Options) $null $null
	RegisterHelper $dump_state "CreateRegex"
}


function CreatePSObject($contents) { $o = new-object psobject; $contents | % { $o | add-member @_ }; ,$o }

function PredPSObject([Hashtable]$dump_state, $context)
{
	DumpPSObject $dump_state $context -predicate
}


function DumpPSObject([Hashtable]$dump_state, $context, [switch]$predicate)
{
	$can_serialize = $true
	$contents = @()

	$members = @(get-member -inputobject $o)
	foreach ($member in $members)
	{
		if ($member.MemberType -eq "Method")
		{
			# allow standard methods common to all psconfig objects.  these will be
			# created automatically.  fail on any other unrecognized method.
			if ($member.Name -ne "Equals" -and $member.Name -ne "GetHashCode" -and
				$member.Name -ne "GetType" -and $member.Name -ne "ToString")
			{
				$can_serialize = $false
				break
			}
		}
		elseif ($member.MemberType -eq "NoteProperty")
		{
			$contents += @{MemberType = $member.MemberType.ToString(); Name = $member.Name; Value = $o.($member.Name)}
		}
		elseif ($member.MemberType -eq "AliasProperty")
		{
			# extract the property being aliased.  look for the target type as well, if specified.
			if ($member.Definition -match ('^' + $member.Name + ' = \(([A-Za-z0-9_.]{1,})\)([A-Za-z0-9_]{1,})$'))
			{
				$contents += @{MemberType = $member.MemberType.ToString(); Name = $member.Name; Value = $Matches[2]; SecondValue = $Matches[1]}
			}
			elseif ($member.Definition -match ('^' + $member.Name + ' = ([A-Za-z0-9_]{1,})$'))
			{
				$contents += @{MemberType = $member.MemberType.ToString(); Name = $member.Name; Value = $Matches[1]}
			}
			else
			{
				$can_serialize = $false
				break
			}
		}
		elseif ($member.MemberType -eq "ScriptMethod")
		{
			$contents += @{MemberType = $member.MemberType.ToString(); Name = $member.Name; Value = $o.($member.Name).Script}
		}
		else
		{
			# MemberSet / PropertySet / ParameterizedProperty
			#    These may be reproducable.  They are worth further investigation if demand warrants it.
			# ScriptProperty
			#    The definition string is not precise enough to separate the getter and the optional
			#    setter.  the token which separates the two (';set=') could appear in either block,
			#    causing a mismatch.
			$can_serialize = $false
			break
		}
	}

	if ($predicate)
	{
		$can_serialize
	}
	else
	{
		DumpArrayObject $dump_state $contents
		RegisterHelper $dump_state "CreatePSObject"
	}
}


function CustomizeCollection($context, [Hashtable]$members_to_skip, [Hashtable]$members_to_add)
{
	$members_to_skip["SyncRoot"] = 1
	$members_to_add["Contents"] = @($context.o)
}


function CustomizeBitArray($context, [Hashtable]$members_to_skip, [Hashtable]$members_to_add)
{
	$members_to_skip["SyncRoot"] = 1
	$members_to_skip["Length"] = 1
	$members_to_add["Contents"] = @($context.o)
}


function CustomizeSortedList($context, [Hashtable]$members_to_skip, [Hashtable]$members_to_add)
{
	$members_to_skip["SyncRoot"] = 1
	$members_to_skip["Keys"] = 1
	$members_to_skip["Values"] = 1
	$contents = @{}
	foreach ($key in $context.o.Keys)
	{
		$contents[$key] = $context.o[$key]
	}
	$members_to_add["Contents"] = $contents
}


Initialize

Export-ModuleMember -Function @('*') -Alias @('ctsb', 'dump')
